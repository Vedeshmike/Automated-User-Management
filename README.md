# 🔐 Automated User Management (AUM) - Salesforce

AUM (Automated User Management) is a native Salesforce project built to **simplify and automate user permission assignments** perfect for Salesforce Admins who want to eliminate repetitive tasks and streamline user provisioning.

---

## 🚀 Current Feature: Permission Set Assignment

This feature automatically assigns Permission Sets to Users based on dynamic rules defined by the Admin. No more manual checks and assignments!

### ✅ How It Works

1. **Create a Rule**  
   Define a dynamic provisioning rule using combinations of:
   - Job Title  
   - Department  
   - Role  
   - Profile  
   - Permission Sets  
   - Permission Set Groups *(optional)*

2. **Trigger Execution**  
   When a User is **created or updated**, the system checks if a matching rule exists and automatically assigns the associated permission sets.

---

## 💡 Use Case Example

Imagine you have 10 new users joining from the Sales department. You’ve already defined a rule:
> If Job Title = "Sales Executive" and Department = "Sales", assign Permission Sets: `Sales_Access`, `Reports_View`.

The system will automatically assign those permission sets the moment a user is added or updated. Zero clicks from your side.

---

## 🔄 What’s Coming Next

This project is **under active development**. Some of the upcoming features include:

- 📊 **User License Dashboard** – Quickly view license usage and availability.
- 🤖 **Admin AI Agent** – Ask real-time questions like “How many Salesforce licenses are available?”
- 🧠 **Smart Suggestions** – AI-powered suggestions for Licenses based on usage patterns.

---

## ⚙️ Installation & Setup

> ⚠️ Currently, this project is installed manually in Developer Orgs. Unmanaged package link coming soon.

To test:
1. Clone this repo or deploy the metadata to your org.
2. Use the **"User Provisioning Rule"** Lightning Component to create dynamic rules.
3. Create or update a User and watch the automation assign permission sets.

---

## 🤝 Contributing

This started off as a fun experiment while exploring ideas in my Dev Org, and now it’s becoming a fully-fledged Admin tool. If you have ideas, feedback, or want to contribute — I’d love to connect!

---

## 📬 Contact

Feel free to reach out to me on [LinkedIn](https://www.linkedin.com/in/vedeshnadar/) or drop a comment if you're using the tool or want to collaborate.

---

## 📄 License

MIT – Open to all!

---
