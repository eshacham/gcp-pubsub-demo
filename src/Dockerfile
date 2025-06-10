# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements_subscriber.txt .

# Install any needed packages specified in requirements.txt
# Using --no-cache-dir to reduce image size
RUN pip install --no-cache-dir -r requirements_subscriber.txt

# Copy the subscriber script into the container at /app
COPY subscriber.py .

# Environment variables (GCP_PROJECT_ID, PUBSUB_SUBSCRIPTION_ID, etc.)
# will be passed in at runtime by the chosen cloud platform.

# Run subscriber.py when the container launches
CMD ["python", "subscriber.py"]
