# RDBMS vs NoSQL

## Database Recommendation

**Recommendation: MySQL (RDBMS) as the primary system — with a targeted MongoDB component for the fraud detection module.**

A patient management system is one of the most demanding environments for data integrity. Patient records — diagnoses, prescriptions, lab results, surgical notes — must be **accurate, consistent, and durable**. MySQL's full ACID guarantees make it the correct choice here:

- **Atomicity** ensures that a medication update and the corresponding audit log entry either both succeed or both fail. There is no risk of a partial write leaving a patient's record in an invalid state.
- **Consistency** enforces referential integrity: a prescription row cannot reference a non-existent patient or drug. Foreign keys and CHECK constraints encode business rules directly into the schema.
- **Isolation** prevents concurrent writes from a nurse and a physician from corrupting the same record. Serialisable isolation levels handle high-concurrency ICU environments.
- **Durability** means a committed discharge record survives a server crash.

From a **CAP theorem** perspective, MySQL prioritises **Consistency and Partition Tolerance** (CP). In healthcare, data consistency is non-negotiable — BASE semantics (MongoDB's default, which allows temporary inconsistencies) are unacceptable when a stale drug dosage record could harm a patient.

**However, the fraud detection module changes the calculus.** Fraud detection is about finding patterns across high-velocity, heterogeneous event streams — login timestamps, billing transactions, location pings, document uploads. These events have *varied shapes* that are difficult to express in a rigid relational schema. MongoDB's schema flexibility, horizontal scaling, and native support for nested event documents make it an excellent fit here. Since fraud flags are a *derived output* (not the source of truth for clinical records), BASE consistency is acceptable: a brief delay in surfacing a fraud alert is tolerable, whereas a delayed drug record is not.

**Final recommendation:** Use MySQL for the core patient management system and a time-series or document store (MongoDB) for the fraud detection event pipeline. The two systems coexist without compromising the integrity of clinical data.
