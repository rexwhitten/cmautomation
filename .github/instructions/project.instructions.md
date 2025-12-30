# Project Instructions: Cloud Posture Maturity Tool

This tool is designed to help organizations assess and improve their cloud security posture. It provides a structured approach to evaluate current practices, identify gaps, and implement best practices for cloud security.

It utilizes imports from various sources to gather data and insights, ensuring a comprehensive assessment of the organization's cloud security maturity.

## Sources

- AWS CloudWatch, SecurityHub, Config
- Azure Security Center, Monitor
- wiz.io
- Katana
- coralogix

## Synopsis

This propject provides onboarding for a typical parent org that is aquiring child-orgs. It will help the parent org assess the cloud security posture of the child-orgs and provide recommendations for improvement.

## Features

- Lambda function for onbarding: creates the necessary database schema in Aurora (PostgreSQL), also creates child-org credentials in Vault (ie, AWS, Azure, the Wiz, etc)
- Normalized Data Model: designed to store cloud security posture data from multiple sources in a consistent format.
- Lambda functions for import: one per source, normalizing the data for storing in Aurora (PostgreSQL)
- HTML5/CSS3/TypeScript frontend: provides a user-friendly interface for visualizing the cloud security posture data and generating reports. (ideally framework less)
- Authentication: During onboarding a token is generated and sent to the child-org/admin email. This email contgians a link that completes the onboarding process by setting a password. All subsequent logins require the email and password/key.
- Remediation Planning Functions: Lambda functions that provide JIRA items or Backlog items to remediate identified security issues based on the assessment data.
- Reporting Functions: Lambda functions that generate detailed reports on cloud security posture, highlighting strengths, weaknesses, and recommendations for improvement.

## Workflow

1. **Onboarding a Child Organization**

   - Parent org admin initiates onboarding via the frontend.
   - Lambda function creates the required database schema in Aurora (PostgreSQL).
   - Child-org credentials are generated and stored in Vault for AWS, Azure, Wiz, etc.
   - An authentication token is sent to the child-org admin’s email.
   - The child-org admin completes onboarding by setting a password via the emailed link.

2. **Data Import and Normalization**

   - Scheduled or on-demand Lambda functions run for each data source (AWS, Azure, Wiz, Katana, Coralogix).
   - Each Lambda function collects security posture data and normalizes it for storage in Aurora.

3. **Assessment and Visualization**

   - The frontend retrieves normalized data from Aurora.
   - Users can view dashboards and reports showing the current cloud security posture, strengths, and weaknesses.

4. **Remediation Planning**

   - Lambda functions analyze assessment data and generate remediation items (JIRA/Backlog) for identified issues.
   - Remediation tasks are assigned to the appropriate teams.

5. **Reporting**

   - Lambda functions generate detailed reports summarizing posture, gaps, and recommendations.
   - Reports are available for download or can be sent to stakeholders.

6. **Continuous Improvement**
   - The process repeats as new data is imported and posture is reassessed.
   - Remediation progress is tracked and visualized in the frontend.
