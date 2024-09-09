Users provisioning
===

This guide provides instructions for provisioning users in a system with 
security enabled. It details how to configure the admin and provisioner 
accounts, as well as additional users.

## Warning

Once security is enabled and GraphDB is provisioned, any changes made to the 
`values.yaml` file and the `users.js` file will no longer take effect.

## Configuring the admin and provisioner

This section shows how to enable security and configure the admin and provisioner accounts.

```yaml
security:
  enabled: true
  admin:
    initialPassword: "{bcrypt}$2a$12$VDd8PrAndaJfoMJFlHFot.osSxZWQjMQZKgrEJgVZKFj6WFPvkbnS" # admin123
  provisioner:
    username: graphdb-provisioner
    password: provisionerpass123
```

We can also specify a bcrypt-hashed version of the password for the provisioner as well. 
This may be necessary when using CI/CD tools that detect the hash changes with each 
deployment, potentially triggering events based on false-positive drift.

```yaml
security:
  enabled: true
  provisioner:
    username: graphdb-provisioner
    passwordHash: "{bcrypt}$2a$12$ne8KIDfRmlPUbflsDpPjceDkA9nV2a5Xa.ArIRJ.9zR8iLbV1SYHK" # provisionerpass123
```

**Note: The password for the admin user is created by appending the bcrypt-hashed version
of the password to the "{bcrypt}" string.**

## Configuring extra users

This section demonstrates how to configure additional users in a system with security enabled. 
It provides a YAML example that adds a user named "tester" with a bcrypt-hashed password and 
assigns the "ROLE_USER" authority.

```yaml
security:
  enabled: true
  initialUsers:
    users:
      tester:
        username: tester
        password: "{bcrypt}$2a$12$Ox/aDv4TpnVrMZPmCBNdbu1WI8ekuXiYWMuMie.fpHb.uWRukej1i" # password123
        grantedAuthorities: [ "ROLE_USER" ]
```

**Note: The password for the additional user is created by appending the bcrypt-hashed version
of the password to the "{bcrypt}" string.**

## Configuring users by using a Secret

This section explains how to provision users using a custom Secret defined in the 
[graphdb-users.yaml](./graphdb-users.yaml) file. This file includes descriptions 
of all users, with each user's password stored by appending the bcrypt-hashed 
version of the password to the {bcrypt} string.

```yaml
security:
  enabled: true
  initialUsers:
    existingSecret: "graphdb-users"
    secretKey: users.js
```

#### Credentials

| Username | Password |
|----------|----------|
| admin    | admin    |
| tester   | tester   |
