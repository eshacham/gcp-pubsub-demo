import os
from google.cloud import pubsub_v1

# Read configuration from environment variables
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
TOPIC_ID = os.getenv("PUBSUB_TOPIC_ID")

def publish_messages(project_id: str, topic_id: str):
    """Publishes multiple messages to a Pub/Sub topic."""

    if not project_id or not topic_id:
        print("Error: GCP_PROJECT_ID and PUBSUB_TOPIC_ID environment variables must be set.")
        return

    publisher = pubsub_v1.PublisherClient()
    # The `topic_path` method creates a fully qualified identifier
    # in the form `projects/{project_id}/topics/{topic_id}`
    topic_path = publisher.topic_path(project_id, topic_id)

    for n in range(1, 10):
        data_str = f"Message number {n}"
        # Data must be a bytestring
        data = data_str.encode("utf-8")
        # When you publish a message, the client returns a future.
        future = publisher.publish(topic_path, data)
        print(future.result())

    print(f"Published messages to {topic_path}.")

def main():
    """Main function to run the publisher."""
    publish_messages(PROJECT_ID, TOPIC_ID)

if __name__ == "__main__":
    main()
