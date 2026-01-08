---
applyTo: "**/*.{tf,py}"
---

# DynamoDB Operational Rules

These rules apply to Terraform and Python files interacting with DynamoDB.

## 1. Terraform Definition (`*.tf`)

- **Billing Mode**: Set `billing_mode = "PAY_PER_REQUEST"` unless specific throughput requirements exist.
- **Attributes**: Only define attributes used in Key Schemas (Hash Key, Range Key) or Indexes. Do not define all attributes in Terraform.
- **Protection**: Consider enabling `point_in_time_recovery` for production tables.

## 2. Python Interaction (Boto3)

- **Serialization**: Use `boto3.resource('dynamodb')` or `TypeSerializer`/`TypeDeserializer` to handle DynamoDB JSON format automatically.
- **Error Handling**: Catch `ClientError` and handle exceptions like `ProvisionedThroughputExceededException` (though less likely with On-Demand) or `ConditionalCheckFailedException`.
- **Pagination**: Always handle pagination (`LastEvaluatedKey`) when scanning or querying potentially large result sets.

## 3. Querying & Scanning

- **Prefer Query**: Always prefer `Query` operations over `Scan`.
- **Scan filters**: If using `Scan`, understand it reads the whole table first (cost implication).
- **Projections**: Use `ProjectionExpression` to retrieve only needed attributes to save network bandwidth.

## 4. Updates

- **Update Expression**: Use `update_item` with `UpdateExpression` rather than `put_item` for modifying existing items to avoid overwriting entire items unintentionally.
- **Conditions**: Use `ConditionExpression` to ensure data integrity during concurrent updates.
