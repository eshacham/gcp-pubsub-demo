import os
import json # For creating the final JSON file
import threading # For the event to signal completion
from concurrent.futures import TimeoutError
from google.cloud import pubsub_v1
from google.cloud import storage # For GCS

# Read configuration from environment variables
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SUBSCRIPTION_ID = os.getenv("PUBSUB_SUBSCRIPTION_ID")
TARGET_GCS_BUCKET_NAME = os.getenv("TARGET_GCS_BUCKET_NAME")
EXPECTED_MESSAGES_COUNT = int(os.getenv("EXPECTED_MESSAGES_COUNT", "10")) # Default if not set
OUTPUT_GCS_FILENAME = os.getenv("OUTPUT_GCS_FILENAME", "aggregated_messages.json")

# Number of seconds the subscriber should listen for messages
# TIMEOUT = 5.0 # We will use EXPECTED_MESSAGES_COUNT instead of a timeout

# Initialize GCS client globally as it will be used after the subscriber loop
storage_client = storage.Client()
accumulated_messages_data = [] # List to store decoded message data
received_all_event = threading.Event() # Event to signal when all messages are received


def process_and_accumulate_message(message: pubsub_v1.subscriber.message.Message):
    """Processes a single message, decodes it, and adds it to a global list."""
    global accumulated_messages_data # We are modifying this global list
    global received_all_event      # We are accessing this global event

    try:
        # Assuming each message.data is a UTF-8 encoded string,
        # representing a single JSON object.
        decoded_data_str = message.data.decode("utf-8")
        # Parse the string data into a Python dictionary (JSON object)
        message_json_obj = json.loads(decoded_data_str)
        accumulated_messages_data.append(message_json_obj)
        print(f"Received and accumulated message ID: {message.message_id} ({len(accumulated_messages_data)}/{EXPECTED_MESSAGES_COUNT})")
        message.ack()

        if len(accumulated_messages_data) >= EXPECTED_MESSAGES_COUNT:
            print(f"All {EXPECTED_MESSAGES_COUNT} expected messages received. Signaling to stop.")
            received_all_event.set() # Signal that all messages are received

    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from message {message.message_id}: {e}. Data (first 100 chars): '{message.data.decode()[:100]}...'")
        # Decide how to handle: nack for retry, or ack to discard (potential data loss).
        # For this example, we'll ack to prevent a poison pill loop.
        message.ack()
        print(f"Malformed JSON message {message.message_id} acknowledged to prevent redelivery.")
    except Exception as e:
        print(f"Error processing message {message.message_id}: {e}")
        # Ack to prevent redelivery loop for unexpected errors during processing.
        message.ack()
        print(f"Problematic message {message.message_id} acknowledged.")


def upload_aggregated_data_to_gcs(bucket_name: str, file_name: str, data_list: list):
    """Uploads the list of accumulated (JSON) objects as a single JSON array file to GCS."""
    if not data_list:
        print("No data accumulated to upload.")
        return

    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)

        # Convert the list of Python objects (dictionaries) into a JSON array string
        json_array_string = json.dumps(data_list, indent=2) # indent for readability

        blob.upload_from_string(json_array_string, content_type='application/json')
        print(f"Successfully uploaded {len(data_list)} messages as '{file_name}' to gs://{bucket_name}/")
    except Exception as e:
        print(f"Failed to upload aggregated data to GCS: {e}")


def consume_and_aggregate_messages(
    project_id: str, subscription_id: str, target_bucket_name: str,
    expected_count: int, output_filename: str
):
    """Consumes a specific number of messages, aggregates them, and uploads as one file."""
    global received_all_event # Allow modification from callback
    global accumulated_messages_data

    if not all([project_id, subscription_id, target_bucket_name, output_filename]):
        print(
            "Error: GCP_PROJECT_ID, PUBSUB_SUBSCRIPTION_ID, TARGET_GCS_BUCKET_NAME, "
            "and OUTPUT_GCS_FILENAME environment variables must be set."
        )
        return
    if expected_count <= 0:
        print("Error: EXPECTED_MESSAGES_COUNT must be a positive integer.")
        return

    subscriber = pubsub_v1.SubscriberClient()
    # Check if the provided subscription_id is already a full path
    if "projects/" in subscription_id and "/subscriptions/" in subscription_id:
        subscription_path = subscription_id
        print(f"Using provided full subscription path: {subscription_path}")
    else:
        # Assume it's a short ID and construct the full path
        subscription_path = subscriber.subscription_path(project_id, subscription_id)

    def callback(message: pubsub_v1.subscriber.message.Message) -> None:
        process_and_accumulate_message(message)

    streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)
    print(f"Listening for {expected_count} messages on {subscription_path}...")

    try:
        # Wait until the received_all_event is set by the callback
        # You could add a timeout to received_all_event.wait(timeout=SOME_GLOBAL_TIMEOUT)
        # to prevent indefinite blocking if fewer than expected messages arrive.
        received_all_event.wait()
        print("Stop event received. Proceeding to finalize.")
    except KeyboardInterrupt:
        print("Keyboard interrupt received. Shutting down...")
    finally:
        if streaming_pull_future:
            print("Cancelling Pub/Sub message stream...")
            streaming_pull_future.cancel()  # Trigger the shutdown.
            try:
                streaming_pull_future.result(timeout=60) # Wait for shutdown with a timeout
                print("Message stream shutdown complete.")
            except TimeoutError:
                print("Timeout waiting for message stream to shut down.")
            except Exception as e: # Catch other potential errors during future.result()
                print(f"Error during message stream shutdown: {e}")
        if subscriber:
            subscriber.close() # Ensure client is closed

    # After the subscriber loop has finished (either by event or interrupt)
    print(f"\n--- Uploading Aggregated Data ({len(accumulated_messages_data)} messages) ---")
    upload_aggregated_data_to_gcs(target_bucket_name, output_filename, accumulated_messages_data)
    print("Subscriber process finished.")

def main():
    """Main function to run the subscriber."""
    consume_and_aggregate_messages(
        PROJECT_ID,
        SUBSCRIPTION_ID,
        TARGET_GCS_BUCKET_NAME,
        EXPECTED_MESSAGES_COUNT,
        OUTPUT_GCS_FILENAME
    )

if __name__ == "__main__":
    main()