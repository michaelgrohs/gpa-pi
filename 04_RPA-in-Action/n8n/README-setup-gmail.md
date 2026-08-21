# Connecting a Gmail account to n8n

Both workflows in this folder can use a real Gmail account instead of a throwaway test inbox:
the [purchase approval workflow](README-purchase-order.md) to actually send an email, and the
[email triage workflow](README-email-triage.md) to read real incoming mail. Both use n8n's
generic **SMTP** (send) and **IMAP** (read) credentials with a Gmail **app password** — not
n8n's separate OAuth-based "Gmail" node, which isn't used by either workflow here.

**Strongly recommended: use a personal/throwaway Gmail account for this, not a university or
work account.** School/work Google accounts are frequently locked down by an admin in ways
that block the steps below entirely (see "If app passwords aren't available" below), and even
when they aren't, you probably don't want a classroom exercise reading or sending real mail
from your institutional inbox.

## 1. Turn on 2-Step Verification

App passwords only exist once 2-Step Verification is turned on for the account. Check/enable it
at [myaccount.google.com/signinoptions/two-step-verification](https://myaccount.google.com/signinoptions/two-step-verification).
If it's already on, skip to the next step.

## 2. Generate an app password

Go to [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords), sign in
again if asked, give it a name (e.g. "n8n"), and click **Create**. Google shows you a
**16-character password** — copy it now, it won't be shown again (though you can revoke it and
generate a new one anytime from the same page). This is a separate password from your normal
Gmail password; use it only in n8n's credential fields below, never your real password.

### If app passwords aren't available

The "App Passwords" option is missing or greyed out if:

- **2-Step Verification isn't fully turned on** — go back to step 1.
- **It's a work/school (Google Workspace) account** and the admin has disabled app passwords
  org-wide — there's no user-side fix; use a personal Gmail account instead.
- **2-Step Verification is set up only with a security key**, or **Advanced Protection** is
  enabled on the account — both intentionally block app passwords for extra security.

## 3. Set up the IMAP credential (reading mail — email triage workflow)

In n8n, open your mail-reading node's **Credential** field → **Create New** → IMAP:

| Field | Value |
|---|---|
| User | your full Gmail address |
| Password | the 16-character app password (no spaces) |
| Host | `imap.gmail.com` |
| Port | `993` |
| SSL/TLS | on |

## 4. Set up the SMTP credential (sending mail — purchase approval workflow)

In n8n, open your Send Email node's **Credential** field → **Create New** → SMTP:

| Field | Value |
|---|---|
| User | your full Gmail address |
| Password | the same 16-character app password |
| Host | `smtp.gmail.com` |
| Port | `587` |
| SSL/TLS | off (587 uses STARTTLS, not implicit TLS — same gotcha as the Ethereal setup in [README_purchase-order.md](README-purchase-order.md); alternatively use port `465` with SSL/TLS **on**) |

Update the recipient field on the same node to wherever you want the notification to actually
land.

## Troubleshooting

- **"Invalid login" / "Username and Password not accepted."** Almost always means you pasted
  your real Gmail password instead of the app password, or copied the app password with a
  stray space. Regenerate a fresh app password and paste it exactly as shown (spaces in the
  displayed password are just for readability — n8n's password field doesn't care either way,
  but re-copying cleanly avoids the doubt).
- **Nothing happens when a new email arrives.** The Email Trigger (IMAP) node polls on an
  interval — it isn't instant. Check the node's polling interval, and check n8n's Executions
  list to confirm it's actually running on schedule rather than silently failing.
- **Gmail sending limits.** A regular Gmail account is capped at 500 outgoing messages/day
  (2,000/day for Google Workspace). Irrelevant for classroom-scale testing, but worth knowing
  if you're debugging why a mail stopped sending after a lot of repeated test runs.
- **Two-factor prompts / "This device isn't recognized" emails from Google.** Expected the
  first time or two you use a new app password — it's Google's normal account-activity
  notification, not an error in the workflow. It doesn't require any action beyond the app
  password already having been created.
