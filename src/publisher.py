import os
import json
from google.cloud import pubsub_v1
from google.cloud import storage

# Read configuration from environment variables
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
TOPIC_ID = os.getenv("PUBSUB_TOPIC_ID")
# New: For reading the source file from GCS (primarily for local testing or direct invocation)
SOURCE_GCS_BUCKET_NAME = os.getenv("SOURCE_GCS_BUCKET_NAME")
SOURCE_GCS_FILE_NAME = os.getenv("SOURCE_GCS_FILE_NAME")

def publish_messages_from_gcs_file(
    project_id: str, topic_id: str, bucket_name: str, file_name: str
):
    """
    Downloads a JSON file from GCS, parses it (expecting a list of objects),
    and publishes each object as a separate message to a Pub/Sub topic.
    """

    if not all([project_id, topic_id, bucket_name, file_name]):
        print(
            "Error: GCP_PROJECT_ID, PUBSUB_TOPIC_ID, SOURCE_GCS_BUCKET_NAME, "
            "and SOURCE_GCS_FILE_NAME environment variables must be set for direct execution."
        )
        return

    storage_client = storage.Client()
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)
    published_message_ids = []

    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        file_content_str = blob.download_as_text()
        
        # Assuming the file content is a JSON array of objects
        messages_to_publish = json.loads(file_content_str)

        if not isinstance(messages_to_publish, list):
            print(f"Error: Expected a JSON list in {file_name}, but got {type(messages_to_publish)}.")
            return

        print(f"Found {len(messages_to_publish)} messages in gs://{bucket_name}/{file_name} to publish.")

        for i, message_obj in enumerate(messages_to_publish):
            # Convert the Python object back to a JSON string to be the message data
            data_str = json.dumps(message_obj)
            data = data_str.encode("utf-8")
            
            future = publisher.publish(topic_path, data)
            message_id = future.result() # Blocks until published, good for smaller batches
            published_message_ids.append(message_id)
            print(f"Published message {i+1}/{len(messages_to_publish)} (ID: {message_id}) from {file_name} to {topic_path}.")

    except FileNotFoundError:
        print(f"Error: File gs://{bucket_name}/{file_name} not found.")
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from gs://{bucket_name}/{file_name}.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

    print(f"Finished publishing. Total messages published: {len(published_message_ids)}.")

def main():
    """Main function to run the publisher, reading from GCS."""
    publish_messages_from_gcs_file(
        PROJECT_ID, TOPIC_ID, SOURCE_GCS_BUCKET_NAME, SOURCE_GCS_FILE_NAME
    )

if __name__ == "__main__":
    main()
