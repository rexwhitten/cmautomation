FROM public.ecr.aws/lambda/python:3.12

# Install system dependencies (if needed)
# RUN yum install -y ...

# Install Python dependencies
COPY requirements.txt ./
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy all lambda logic, handlers, and frontend proxy code
COPY lambdas/ lambdas/
COPY handlers.py ./

# Set the default handler (can be overridden per Lambda in AWS)
# Example: handlers.onboarding_handler
ENV AWS_LAMBDA_HANDLER handlers.onboarding_handler

# If you want to include the frontend assets in the image (optional):
# COPY frontend/ frontend/

# Command is provided by the Lambda base image
