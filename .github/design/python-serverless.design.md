This is a robust expansion of your initial design axioms. The goal here is to elevate the guidelines from simple "rules of thumb" to a structured engineering philosophy that applies **SOLID principles** and **Cloud Native patterns** specifically to the Python Serverless runtime (e.g., AWS Lambda).

---

# Python Serverless Design Manifesto

This document outlines the architectural standards for building maintainable, scalable, and robust Python Serverless applications. It merges cloud-native constraints with traditional software engineering rigor.

## I. Core Architectural Axioms

_Foundational rules for the Serverless runtime environment._

### 1. Radical Statelessness

- **The Rule:** No execution context shall assume the existence of state from a previous execution.
- **The "Why":** FaaS providers (like AWS) reuse execution environments (warm starts) but recycle them unpredictably. Local variables are ephemeral.
- **Best Practice:**
- Externalize all persistence to low-latency stores (DynamoDB, ElastiCache/Redis).
- **Exception:** Use the global scope _only_ for static configuration and initializing heavy clients (e.g., `boto3.client`) to take advantage of execution environment reuse.

### 2. Idempotency & Re-entrancy

- **The Rule:** The system must produce the same outcome whether an event is processed once or multiple times.
- **The "Why":** Serverless event sources often guarantee "at-least-once" delivery. Retries on network failures can duplicate requests.
- **Best Practice:**
- Use **Idempotency Keys** (transaction IDs) in your payloads.
- Implement checks using the standard library `aws_lambda_powertools.utilities.idempotency` to prevent processing the same payload twice.

### 3. Hexagonal Architecture (Ports and Adapters)

- **The Rule:** Decouple your business logic from the cloud provider.
- **The "Why":** Writing logic directly inside the `lambda_handler` makes code hard to test and locks you into a specific vendor.
- **Best Practice:**
- **The Handler is an Interface:** The `lambda_handler` should only parse the event, validate inputs, and call a pure Python controller/service class.
- **Domain Logic is Pure:** Your core logic should be testable without `import boto3` or mocking Lambda context objects.

---

## II. SOLID Principles in a Serverless Context

_Applying Object-Oriented design to functional infrastructure._

### S - Single Responsibility Principle (SRP)

- **In Serverless:** A function should change for only one reason.
- **The Anti-Pattern:** The "Lambdalith"—a single function routing multiple endpoints (`/get-user`, `/update-user`, `/delete-user`) via `if/else` statements.
- **Refactoring:** Break these into discrete functions. This reduces package size, minimizes IAM permission scope (Security), and isolates failure domains.

### O - Open/Closed Principle

- **In Serverless:** Software entities should be open for extension, but closed for modification.
- **Application:** Use **Python Decorators** (Middleware pattern) to handle cross-cutting concerns like logging, validation, and tracing.
- **Example:**

```python
@logger.inject_lambda_context
@tracer.capture_lambda_handler
@validator(inbound_schema=UserSchema)
def handler(event, context):
    # Business logic remains untouched when we change logging standards
    return user_service.process(event)

```

### L - Liskov Substitution Principle

- **In Serverless:** Subclasses (or implementations) should be substitutable for their base classes.
- **Application:** When interacting with external services (Database, Queue), define an abstract base class (Protocol in Python). This allows you to swap a real `DynamoDBService` with a `MockInMemoryDB` during local testing without changing the handler logic.

### I - Interface Segregation Principle

- **In Serverless:** Clients should not be forced to depend on interfaces they do not use.
- **Application:** Do not create massive generic "Event Parsers" that try to handle S3, API Gateway, and SQS events simultaneously. Create specific, small data transfer objects (DTOs) or Pydantic models for the specific payload expected by that specific function.

### D - Dependency Inversion Principle

- **In Serverless:** Depend on abstractions, not concretions.
- **Application:** Do not instantiate database clients _inside_ your business logic class. Inject them.
- **Example:**

```python
# Bad
class UserService:
    def __init__(self):
        self.db = boto3.client('dynamodb') # Hard dependency

# Good (Dependency Injection)
class UserService:
    def __init__(self, db_repository: StorageInterface):
        self.db_repository = db_repository

# Wiring happens in the global scope or handler
def lambda_handler(event, context):
    service = UserService(DynamoDBRepository())
    return service.execute(event)

```

---

## III. Python Specific Best Practices

_Optimizing the runtime._

### 1. Initialization Logic (Cold Start Optimization)

Code outside the handler function runs when the container is created (Cold Start). Code inside runs on every invocation.

- **Do:** Initialize database connections, load ML models, and fetch secrets _outside_ the handler.
- **Do:** Use "Lazy Loading" for heavy libraries that are only used in specific branches of logic to reduce import time.

### 2. Structured Logging & Error Handling

Text logs are unsearchable at scale.

- **Requirement:** Output logs as JSON.
- **Requirement:** Use custom Exception classes (`UserNotFound`, `PaymentDeclined`) rather than generic `Exception`.
- **Traceability:** Include the `request_id` and `correlation_id` in every single log line to trace a transaction across multiple Lambda functions.

### 3. Environment Variables & Configuration

Follow the **12-Factor App** methodology.

- Never hardcode configuration.
- Use Environment Variables for non-sensitive config (e.g., `LOG_LEVEL`, `TABLE_NAME`).
- Use a secrets manager (e.g., AWS Secrets Manager/SSM Parameter Store) for sensitive data. Retrieve these at runtime (and cache them), do not bake them into environment variables if possible.

---

## IV. Summary Checklist

| Category        | Principle            | Implementation                                                        |
| --------------- | -------------------- | --------------------------------------------------------------------- |
| **Resilience**  | Idempotency          | Use transaction tokens; ensure retries don't corrupt data.            |
| **Design**      | SRP                  | One Event Type = One Handler.                                         |
| **Design**      | Dependency Inversion | Inject DB clients; don't `new` them in logic classes.                 |
| **Ops**         | Observability        | JSON Logging + Distributed Tracing (e.g., X-Ray).                     |
| **Security**    | Least Privilege      | Handlers should only have IAM permissions for resources they _touch_. |
| **Performance** | Global Scope Reuse   | Initialize heavy clients outside the `def handler():`.                |
