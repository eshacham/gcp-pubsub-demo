import os
import json
from google.cloud import pubsub_v1
from google.cloud import storage

# These will be set as environment variables in the Cloud Function's Terraform configuration
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
PUBSUB_TOPIC_ID = os.getenv("PUBSUB_TOPIC_ID") # This will be the actual topic name, e.g., "gcs-file-events"

# Initialize clients globally to reuse connections across invocations
storage_client = storage.Client()
publisher_client = pubsub_v1.PublisherClient()

def gcs_event_handler(event, context):
    """
    Cloud Function triggered by a GCS event (file upload).
    Downloads the uploaded JSON file, parses it (expecting a list of objects),
    and publishes each object as a separate message to a Pub/Sub topic.

    Args:
         event (dict): Event payload. Contains 'bucket' and 'name' for the GCS object.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    bucket_name = event.get('bucket')
    file_name = event.get('name')
    metageneration = event.get('metageneration')

    print(f"Function triggered by event ID: {context.event_id}, Event Type: {context.event_type}")
    print(f"Processing file: gs://{bucket_name}/{file_name} (metageneration: {metageneration})")

    # Basic check to avoid reprocessing on metadata updates or if the event is not for a new object.
    # '1' usually indicates the first version of an object.
    if metageneration != '1':
        print(f"Skipping file gs://{bucket_name}/{file_name} as it's not a new object (metageneration: {metageneration}).")
        return

    if not all([GCP_PROJECT_ID, PUBSUB_TOPIC_ID, bucket_name, file_name]):
        print("Error: Missing required configuration (GCP_PROJECT_ID, PUBSUB_TOPIC_ID) or event data (bucket/file name).")
        # Consider raising an exception or returning an error status if appropriate
        return

    topic_path = publisher_client.topic_path(GCP_PROJECT_ID, PUBSUB_TOPIC_ID)
    published_count = 0

    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)

        if not blob.exists():
            print(f"Error: File gs://{bucket_name}/{file_name} not found.")
            return

        file_content_str = blob.download_as_text()
        messages_to_publish = json.loads(file_content_str)

        if not isinstance(messages_to_publish, list):
            print(f"Error: Expected a JSON list in gs://{bucket_name}/{file_name}, but got {type(messages_to_publish)}.")
            return

        print(f"Found {len(messages_to_publish)} messages in gs://{bucket_name}/{file_name} to publish to {topic_path}.")

        for i, message_obj in enumerate(messages_to_publish):
            data_str = json.dumps(message_obj)
            data_bytes = data_str.encode("utf-8")
            future = publisher_client.publish(topic_path, data_bytes)
            future.result() # Block to ensure message is sent, get message_id or handle errors
            published_count += 1
        print(f"Successfully published {published_count} messages from gs://{bucket_name}/{file_name}.")
    except Exception as e:
        print(f"Error processing file gs://{bucket_name}/{file_name}: {e}")
        raise  # Re-raise the exception to signal an error to Cloud Functions for potential retry