## Security Considerations
---
### **1. Private Network Communication using Private Endpoint only**
- VNet Peering ensures that all communication between the two offices remains within Azure’s private network, reducing exposure to the public internet. Also we are using Private EndPoint Services which ensures Storage Accounts should be accessed only internally using through endpoint DNS.

### **2. Identity and Access Management**
- We could use Azure Active Directory (AAD) to manage access to resources.
- Enforce multi-factor authentication (MFA) for additional security when users from the US access resources in the EU.

### **3. Network Security Groups (NSGs)**
- NSGs control inbound and outbound traffic. Ensure rules only permit necessary traffic between the US and EU subnets, and block any other connections by default.

### **4. Monitoring and Logging**
- Used **Log Analytics** for real-time monitoring and logging of network traffic, authentication attempts, and encryption statuses.

For example File Share performance from US region user is monitored and shown on performance dashboard.

![Solution Design](./docs/images/Solution_Design.jpeg)

---

## FileShare Access using Private EndPoint and DNS Records

The secure connection between File share goes through private endpoint and Private EndPoint resolved through DNS records for US region internal file access.

![Private EndPoint](./docs/images/Private_Endpoint.png)

DNS Record Entry

![DNS Records](./docs/images/DNS_Records.png)

Storage Account access is disabled by default, so it should not be accessible even within network; if this request is not coming from source and also from allowed source.

![Storage Account not Accessible](./docs/images/Storageaccount_Network_Access_Disabled.png)

