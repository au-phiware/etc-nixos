---
name: mach-migration-sql-review
description: >
  Capture the exact SQL that one or more new FluentMigrator migrations emit in the MachShip
  repo, and post it into the pull-request description as a "Generated SQL (for DB Admin review)"
  section for Sean (the DB admin) to review. Use this whenever a PR adds or changes a database
  migration (anything under Machship.Migrations/Migrations/) and you want Sean to sign off on the
  DDL — especially anything near hot tables like Consignments. Trigger on phrases like: "capture
  the SQL from the migration", "put the migration SQL in the PR for Sean", "get the DDL for the DB
  admin", "rerun the migration and update the SQL in the PR", "send the schema change to Sean", or
  any request to surface raw migration SQL for review. MachShip-specific (FluentMigrator + SQL
  Server + the ghcr machship-sqlserver-docker image).
---

# MachShip: Migration SQL for DB-Admin Review

Your job: produce the **real** SQL a new migration emits, and put it in the PR description so
Sean (the DB admin) can review the schema change. MachShip's hard rule is that the `Consignments`
table must never gain a foreign key, index, or column (it is too large and write-heavy) — Sean is
the human gate for anything risky, so the SQL must be accurate and verified, never hand-waved.

The FluentMigrator runner (`Machship.Migrations/Program.cs`) has **no preview/`--sql` mode** — it
only `MigrateUp()`s against a live connection. So the faithful way to "capture the SQL" is to run
the migration against a throwaway SQL Server container and script the resulting objects from the
live catalog. Do not hand-write the DDL from the C# migration and call it captured.

## Prerequisites

- Docker running, with access to `ghcr.io/machship/machship-sqlserver-docker` (GHCR auth; a PAT
  with `read:packages`). The image ships the `machship` database preloaded (sa / `PassW0rd`).
- The MachShip working tree on the branch whose migration you're reviewing.
- `gh` authenticated, and an open PR for the branch (this skill writes to its description).

## Step 1 — Identify the migration(s) in scope

Find the migration files this branch adds or changes (they live under
`Machship.Migrations/Migrations/<year>/<month>/`):

```bash
git diff --name-only origin/master...HEAD -- 'Machship.Migrations/Migrations/**/*.cs'
```

Read each one. Note the table name(s) it creates/alters and every object it declares
(`Create.Table` / `MachshipTable`, `Create.Index`, inline `.ForeignKey(...)`, `Create.ForeignKey`,
`Alter.Table`, etc.). These are the objects you will script after the run.

> **Hard-rule check (do this early):** if any migration adds a foreign key, index, or column **to
> the `Consignments` table** — or an FK **referencing `Consignments(Id)`** — stop and flag it. That
> violates the MANDATORY rule in `CLAUDE.md` and is exactly what Sean will reject. Confirm intent
> before continuing.

## Step 2 — Build the runner

```bash
dotnet build Machship.Migrations/Machship.Migrations.csproj -c Debug
```

(Debug matches the documented invocation; Release works too. Don't run two `dotnet` builds
concurrently in the same worktree — it throws spurious file-lock errors.)

## Step 3 — Spin up a throwaway SQL Server

Use a dedicated container on a non-default port so you never touch the developer's local stack.

```bash
docker rm -f mig-sql-tmp >/dev/null 2>&1
docker run -d --name mig-sql-tmp -p 1434:1433 ghcr.io/machship/machship-sqlserver-docker:latest

# wait until the preloaded machship DB answers
for i in $(seq 1 40); do
  docker exec mig-sql-tmp /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P PassW0rd -C -No \
    -Q "SELECT name FROM sys.databases WHERE name='machship';" 2>/dev/null | grep -q machship \
    && { echo "ready ($i)"; break; } || sleep 3
done
```

Confirm your migration's table does **not** already exist in the image baseline (if it does, the
image is newer than your branch and the migration would be skipped — pick an older image tag or
rebuild):

```bash
docker exec mig-sql-tmp /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P PassW0rd -C -No -d machship -h -1 \
  -Q "SELECT name FROM sys.tables WHERE name IN ('<YourNewTable>');"
```

## Step 4 — Run the migration

```bash
CONN="Data Source=127.0.0.1,1434;Initial Catalog=machship;User ID=sa;Password=PassW0rd;Persist Security Info=True;TrustServerCertificate=True;"
dotnet Machship.Migrations/bin/Debug/net8.0/Machship.Migrations.dll "$CONN" "e2e"
```

This applies every pending migration (baseline → head), which proves your migration applies in
sequence. The FluentMigrator console log prints the operations per migration, e.g.
`CreateTable JourneyConsignments`, `CreateForeignKey FK_... JourneyConsignments(JourneyId) Journeys(Id)`,
`CreateIndex ...`. Keep this log — it confirms the *operation set* (and confirms what is **absent**,
e.g. no FK to `Consignments`). The log is not literal DDL, though — Step 5 gets the precise SQL.

## Step 5 — Script the real DDL from the live catalog

Query the catalog for each object your migration created. Helper:

```bash
SQL() { docker exec mig-sql-tmp /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P PassW0rd \
  -C -No -d machship -h -1 -W -s '|' -Q "SET NOCOUNT ON; $1" 2>/dev/null; }

T='<YourNewTable>'   # e.g. JourneyConsignments

# Columns: name | type | max_length | precision | scale | nullable | default
SQL "SELECT c.name,t.name,c.max_length,c.precision,c.scale,c.is_nullable,ISNULL(dc.definition,'')
     FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
     LEFT JOIN sys.default_constraints dc ON dc.parent_object_id=c.object_id AND dc.parent_column_id=c.column_id
     WHERE c.object_id=OBJECT_ID('dbo.$T') ORDER BY c.column_id;"

# Identity column, primary key
SQL "SELECT name FROM sys.identity_columns WHERE object_id=OBJECT_ID('dbo.$T');"
SQL "SELECT name,type_desc FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('dbo.$T');"

# Foreign keys: name | referenced table | delete action  (verify NOTHING references Consignments)
SQL "SELECT fk.name,OBJECT_NAME(fk.referenced_object_id),fk.delete_referential_action_desc
     FROM sys.foreign_keys fk WHERE fk.parent_object_id=OBJECT_ID('dbo.$T');"

# Indexes: name | is_unique | type | columns
SQL "SELECT i.name,i.is_unique,i.type_desc,
       (SELECT STRING_AGG(col.name+CASE WHEN ic.is_descending_key=1 THEN ' DESC' ELSE ' ASC' END,', ')
          WITHIN GROUP (ORDER BY ic.key_ordinal)
        FROM sys.index_columns ic JOIN sys.columns col ON col.object_id=ic.object_id AND col.column_id=ic.column_id
        WHERE ic.object_id=i.object_id AND ic.index_id=i.index_id)
     FROM sys.indexes i WHERE i.object_id=OBJECT_ID('dbo.$T') AND i.type>0;"
```

For an `Alter.Table` migration, script only the objects it added/changed (the new column, the new
constraint) rather than the whole table.

Watch the details that catch people out — they must reflect the catalog, not your assumptions:
- MachShip `BaseEntity` columns are `DATETIME` (not `DATETIME2`); `DateCreated DEFAULT (GETUTCDATE())`,
  `IsActive BIT NOT NULL DEFAULT ((1))`, `InsertedBy` is `NOT NULL`, `OrganisationId` is nullable.
- `MachshipTable(name, true)` auto-adds the full `BaseEntity` set **plus** an `FK_<T>_OrganisationId_Organisations_Id`
  FK and an `IX_<T>_Id` index — include these; they're part of what Sean sees.
- Inline `.ForeignKey("name","Table","Col")` defaults to `ON DELETE NO ACTION` (SQL Server's RESTRICT).

## Step 6 — Assemble the SQL block

Write a fenced ```sql block in the order FluentMigrator applies operations (table → `Id` index →
auto `OrganisationId` FK → your FKs → your indexes), one short comment per statement explaining
intent. Where the migration deliberately omits something risky (e.g. no FK on a `Consignments`
arm), include a comment saying so and why — that omission is the point Sean is reviewing.

## Step 7 — Update the PR description for Sean

Fetch the current body, add or replace a section titled **`## Generated SQL (for DB Admin review)`**,
and write it back. Lead the section with one line stating how it was captured and the headline
safety fact (e.g. "nothing references `Consignments`").

```bash
gh pr view <PR#> --json body --jq '.body' > /tmp/pr_body.md
# edit /tmp/pr_body.md: insert/replace the "## Generated SQL (for DB Admin review)" section
gh pr edit <PR#> --body-file /tmp/pr_body.md
```

Then make sure Sean actually sees it. Request him as a reviewer (confirm his GitHub handle — do
not guess it; ask the user or check existing MachShip PRs Sean has reviewed):

```bash
gh pr edit <PR#> --add-reviewer <seans-github-handle>
```

If you also changed prose elsewhere in the body that referenced the old SQL (FK names, "Down"
steps, etc.), reconcile those too so the description doesn't contradict itself.

## Step 8 — Clean up

```bash
docker rm -f mig-sql-tmp >/dev/null 2>&1
```

## Verify before you call it done

- The migration **applied cleanly** in Step 4 (no errors in the runner log).
- The scripted SQL matches the live catalog (Step 5), not the C# source you eyeballed.
- No object touches `Consignments` unless explicitly intended and agreed with Sean.
- The PR body's SQL section and any surrounding prose are consistent with the committed migration
  (`git show HEAD:<migration path>` should match what you described).
- Sean is on the PR (reviewer or @-mention).

## Notes

- The runner applies *all* pending migrations from the image baseline; that's expected and also
  serves as a free "does the whole chain still apply" check. Only script the objects **your**
  migration introduced.
- MachShip does not support down-migrations: `MachshipMigration.Down()` is intentionally a no-op,
  so new migrations should define only `Up()`. Don't document a `Down` in the SQL section.
- Prefer the throwaway container over the developer's local `machship-database-*` stack so you
  never leave their DB half-migrated.
