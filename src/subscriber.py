import os
from concurrent.futures import TimeoutError
from google.cloud import pubsub_v1

# Read configuration from environment variables
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SUBSCRIPTION_ID = os.getenv("PUBSUB_SUBSCRIPTION_ID")
# Number of seconds the subscriber should listen for messages
TIMEOUT = 5.0

def consume_messages(project_id: str, subscription_id: str, timeout: float = TIMEOUT):
    """Consumes messages from a Pub/Sub subscription."""

    if not project_id or not subscription_id:
        print(
            "Error: GCP_PROJECT_ID and PUBSUB_SUBSCRIPTION_ID environment variables must be set."
        )
        return
    # Create a subscriber client
    subscriber = pubsub_v1.SubscriberClient()
    # The `subscription_path` method creates a fully qualified identifier
    # in the form `projects/{project_id}/subscriptions/{subscription_id}`
    subscription_path = subscriber.subscription_path(project_id, subscription_id)
    messages = []

    # Wrap the subscriber in a 'with' block to automatically call close() to
    # close the underlying gRPC channel when done.

    def callback(message: pubsub_v1.subscriber.message.Message) -> None:
        messages.append(message)
        print(f"Received message data: {message.data.decode()}")
        message.ack()

    streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)
    print(f"Listening for messages on {subscription_path}..\n")

    # Wrap subscriber in a 'with' block to automatically call close() when done.
    with subscriber:
        try:
            # When `timeout` is not set, result() will block indefinitely,
            # unless an exception is encountered first.
            streaming_pull_future.result(timeout=timeout)
        except TimeoutError:
            streaming_pull_future.cancel()  # Trigger the shutdown.
            streaming_pull_future.result()  # Block until the shutdown is complete.

    print("\n--- Summary of Consumed Messages (in order) ---")
    if messages:
        for i, msg_obj in enumerate(messages):
            # msg_obj is the full message object, msg_obj.data is the bytestring
            print(f"Message {i+1}: {msg_obj.data.decode()}")
    else:
        print("No messages were consumed during this session.")

def main():
    """Main function to run the subscriber."""
    consume_messages(PROJECT_ID, SUBSCRIPTION_ID)

if __name__ == "__main__":
    main()