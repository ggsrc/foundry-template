{% if cookiecutter.contact_email -%}
# Security Policy

## 🚨 Reporting Security Vulnerabilities

> **⚠️ Do not open public GitHub issues for security vulnerabilities!**

**Contact:** [{{ cookiecutter.contact_email }}](mailto:{{ cookiecutter.contact_email }})

For critical vulnerabilities affecting user funds, use subject: **[CRITICAL] {{ cookiecutter.project_name }} Security**

## What to Include

When reporting a vulnerability, please provide:

- **Contract addresses** and **network/chain**
- **Affected functions** and line numbers
- **Vulnerability type** (reentrancy, access control, etc.)
- **Step-by-step reproduction** instructions
- **Potential impact** and exploitation scenario
- **Proof of concept** code (if available)

---

Thank you for helping keep {{ cookiecutter.project_name }} secure!
{%- endif %} 