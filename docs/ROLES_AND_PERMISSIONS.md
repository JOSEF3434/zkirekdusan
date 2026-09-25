# Zikire Kdusan - Roles and Permissions

## Overview

Zikire Kdusan implements a comprehensive two-tier role-based access control (RBAC) system:

1. **Global Platform Roles** - Apply across the entire platform
2. **Group-Level Roles** - Apply within specific groups

This document explains what each role can actually do based on the verified implementation.

---

## Table of Contents

1. [Global Platform Roles](#global-platform-roles)
2. [Group-Level Roles](#group-level-roles)
3. [Permission System](#permission-system)
4. [Role Comparison Table](#role-comparison-table)
5. [Common Scenarios](#common-scenarios)

---

## Global Platform Roles

### 1. USER (Default Role)

**Description:** Standard platform user with basic content creation and consumption permissions.

**Assigned:** Automatically assigned to all new accounts during registration.

**What USER Can Do:**

**Profile & Account:**
- ✅ View and update own profile
- ✅ Change password and account settings
- ✅ Upload avatar and cover photos
- ✅ Set profile visibility (Public/Followers/Private)

**Content Creation:**
- ✅ Create text, image, and video posts
- ✅ Upload videos to channels (if channel member)
- ✅ Create and share stories (24-hour expiration)
- ✅ Create and share reels
- ✅ Upload media files (images, videos, documents)
- ✅ Start live streams (in groups where they have permission)

**Content Consumption:**
- ✅ Watch public videos
- ✅ Watch live streams
- ✅ View posts, stories, and reels
- ✅ Download videos (if enabled by creator)
- ✅ Search and discover content
- ✅ View trending and recommendations

**Social Features:**
- ✅ Follow/unfollow other users
- ✅ Like, comment on, and share content
- ✅ React to live stream messages
- ✅ Send direct messages
- ✅ Participate in group channels
- ✅ Save/bookmark content

**Groups:**
- ✅ Join public groups
- ✅ Request to join private groups
- ✅ Create new groups (pending admin approval)
- ✅ Post in group channels (if member)
- ✅ Participate in group discussions

**Calendar:**
- ✅ Create Ethiopian calendar notes
- ✅ Set reminders (one-time or recurring)
- ✅ Attach media to calendar entries

**What USER Cannot Do:**
- ❌ Access admin panel
- ❌ Moderate other users' content
- ❌ Approve groups or reports
- ❌ Manage platform-wide settings
- ❌ Assign roles to other users
- ❌ Ban or suspend users
- ❌ View audit logs

---

### 2. SUPPORT

**Description:** Support agent role focused on helping users and resolving tickets.

**What SUPPORT Can Do (in addition to USER permissions):**

**User Support:**
- ✅ View user profiles and account status
- ✅ View user-submitted reports
- ✅ Review support tickets
- ✅ Resolve common user issues

**Reports:**
- ✅ View all reports (users.view, reports.view)
- ✅ Review reported content (reports.review)
- ✅ Resolve or dismiss reports (reports.resolve, reports.dismiss)
- ✅ Escalate complex cases to moderators/admins

**Notifications:**
- ✅ View platform notifications (notifications.view)
- ✅ Send notifications to users (notifications.send - limited scope)

**What SUPPORT Cannot Do:**
- ❌ Delete or moderate content directly
- ❌ Ban or suspend users
- ❌ Access system settings
- ❌ Manage groups or channels
- ❌ View audit logs
- ❌ Assign roles

**Typical Use Cases:**
- Responding to user inquiries
- Handling password reset requests
- Resolving account access issues
- Triaging reports for moderator review

---

### 3. MODERATOR

**Description:** Content moderator responsible for maintaining platform quality and safety.

**What MODERATOR Can Do (in addition to SUPPORT permissions):**

**Content Moderation:**
- ✅ View all media content (media.view, videos.view)
- ✅ Moderate inappropriate media (media.moderate, videos.moderate)
- ✅ Delete violating videos (videos.delete - with oversight)
- ✅ Hide or remove posts and comments

**User Management:**
- ✅ View user accounts and profiles (users.view)
- ✅ Review user activity and history

**Group Management:**
- ✅ View all groups (groups.view)
- ✅ Approve pending groups (groups.approve)
- ✅ Manage group members (groups.manage_members)
- ✅ Suspend problematic groups (groups.suspend - escalation path)

**Channel Management:**
- ✅ View all channels (channels.view)
- ✅ Moderate channel content

**Chat & Messaging:**
- ✅ View chat messages (chat.view)
- ✅ Moderate live stream and channel chat (chat.moderate)
- ✅ Delete inappropriate messages (chat.delete)
- ✅ Manage chat reports (chat.manage_reports)

**Live Streaming:**
- ✅ View all live streams (live.view)
- ✅ Moderate live stream content (live.moderate)
- ✅ Stop violating streams (live.stop)

**Spam Management:**
- ✅ View spam reports (spam.view)
- ✅ Review and classify spam (spam.review)
- ✅ Block spam sources (spam.block)
- ✅ Unblock false positives (spam.unblock)

**What MODERATOR Cannot Do:**
- ❌ Create or delete users
- ❌ Assign platform roles
- ❌ Access system settings
- ❌ Manage storage or cache
- ❌ View full audit logs
- ❌ Permanently ban users (can only suspend)

**Typical Use Cases:**
- Reviewing flagged content
- Moderating live stream chat
- Approving new groups
- Handling content violations
- Enforcing community guidelines

---

### 4. ADMIN

**Description:** Platform administrator with broad management capabilities.

**What ADMIN Can Do (in addition to MODERATOR permissions):**

**User Management:**
- ✅ Create new users (users.create)
- ✅ Update user information (users.update)
- ✅ Delete user accounts (users.delete)
- ✅ Suspend user accounts (users.suspend)
- ✅ Ban users permanently (users.ban)
- ✅ Reset user passwords (users.reset_password)

**Role Management:**
- ✅ View all roles and permissions (roles.view)
- ✅ Assign roles to users (roles.assign)
- ✅ Update role permissions (roles.update)

**Group Management:**
- ✅ Create groups (groups.create)
- ✅ Update group settings (groups.update)
- ✅ Delete groups (groups.delete)
- ✅ Approve/reject group applications (groups.approve)
- ✅ Manage group members across all groups (groups.manage_members)
- ✅ Suspend or archive groups (groups.suspend)

**Channel Management:**
- ✅ Create channels (channels.create)
- ✅ Update channel settings (channels.update)
- ✅ Delete channels (channels.delete)
- ✅ Manage channel members (channels.manage_members)

**Media & Content:**
- ✅ Upload any media (media.upload)
- ✅ Update media metadata (media.update)
- ✅ Delete any media files (media.delete)
- ✅ Moderate all media (media.moderate)
- ✅ Update video details (videos.update)
- ✅ Delete any video (videos.delete)

**Live Streaming:**
- ✅ Manage all live streams (live.manage)
- ✅ Moderate stream content (live.moderate)
- ✅ Stop any stream (live.stop)

**Notifications:**
- ✅ View all notifications (notifications.view)
- ✅ Send platform-wide notifications (notifications.send)
- ✅ Manage notification settings (notifications.manage)

**System & Storage:**
- ✅ View system information (system.view)
- ✅ View storage metrics (storage.view)
- ✅ Manage storage (storage.manage)
- ✅ View audit logs (audit.view)

**What ADMIN Cannot Do:**
- ❌ Modify core system settings (system.settings - SUPER_ADMIN only)
- ❌ Access system configurations directly
- ❌ Override SUPER_ADMIN permissions

**Typical Use Cases:**
- Managing user accounts
- Approving group creations
- Handling escalated moderation cases
- Platform-wide announcements
- Reviewing audit logs
- Managing storage and resources

---

### 5. SUPER_ADMIN

**Description:** Highest privilege level with unrestricted access to all platform features and settings.

**Special Characteristics:**
- ✅ **Wildcard Permission (`*`)** - Bypasses all permission checks
- ✅ Automatically granted access to all resources
- ✅ Cannot be restricted by any guard or permission check
- ✅ Bypasses all group-level role checks

**What SUPER_ADMIN Can Do:**

**Everything ADMIN Can Do, Plus:**
- ✅ Modify system settings (system.settings)
- ✅ Access and modify core configurations
- ✅ Manage all system resources without restriction
- ✅ Override any permission or access control
- ✅ Direct database access (if needed for maintenance)
- ✅ Manage other SUPER_ADMIN accounts

**Critical System Functions:**
- ✅ Platform configuration
- ✅ Database migrations
- ✅ Security settings
- ✅ API keys and secrets management
- ✅ Infrastructure management
- ✅ Disaster recovery

**What SUPER_ADMIN Should Avoid:**
- ⚠️ Daily moderation tasks (delegate to MODERATOR)
- ⚠️ Routine support tickets (delegate to SUPPORT)
- ⚠️ Direct content editing (use ADMIN account)

**Typical Use Cases:**
- System maintenance and updates
- Emergency interventions
- Critical security incidents
- Platform configuration changes
- Granting ADMIN privileges

**Security Note:** SUPER_ADMIN access should be highly restricted and logged. Use ADMIN accounts for day-to-day administration.

---

## Group-Level Roles

Group roles apply only within specific groups and control what members can do within that group context.

### GROUP_ADMIN

**Description:** Full administrative control within a specific group.

**Assignment:**
- Automatically assigned to group creator
- Can be assigned by existing GROUP_ADMIN
- Multiple GROUP_ADMINs allowed per group

**Permissions:**

**Group Management:**
- ✅ Edit group name, description, images
- ✅ Change group visibility (Public/Private/Invite-Only)
- ✅ Archive or delete group
- ✅ Configure group settings

**Member Management:**
- ✅ Invite new members
- ✅ Approve join requests
- ✅ Assign roles (MODERATOR, MEMBER, GUEST)
- ✅ Promote members to MODERATOR or GROUP_ADMIN
- ✅ Remove members from group
- ✅ Ban members permanently

**Content Management:**
- ✅ Create, edit, delete any group post
- ✅ Create and manage channels
- ✅ Pin announcements
- ✅ Moderate all group content
- ✅ Configure channel permissions

**Video Channels:**
- ✅ Create video channels for the group
- ✅ Manage channel settings
- ✅ Control who can upload videos
- ✅ Set download permissions

**Live Streaming:**
- ✅ Create and manage live streams
- ✅ Assign stream moderators
- ✅ Stop any stream in the group
- ✅ Access stream analytics

**Authority:** GROUP_ADMIN is highest group-level role (level 4 in hierarchy).

---

### MODERATOR (Group-Level)

**Description:** Helps maintain group quality and enforce rules.

**Assignment:**
- Assigned by GROUP_ADMIN
- Multiple MODERATOR roles per group

**Permissions:**

**Content Moderation:**
- ✅ Delete inappropriate posts and comments
- ✅ Pin/unpin important messages
- ✅ Moderate channel discussions
- ✅ Review flagged content within group

**Member Interaction:**
- ✅ Mute disruptive members temporarily
- ✅ Warn members for violations
- ✅ Report serious issues to GROUP_ADMIN
- ❌ Cannot remove or ban members (escalate to admin)

**Live Stream Moderation:**
- ✅ Moderate live stream chat
- ✅ Delete inappropriate chat messages
- ✅ Pin important chat messages
- ✅ Timeout users in chat (if implemented)

**What MODERATOR Cannot Do:**
- ❌ Change group settings
- ❌ Invite or remove members
- ❌ Assign roles
- ❌ Delete group or channels
- ❌ Access group analytics

**Authority:** Level 3 in group hierarchy.

---

### MEMBER

**Description:** Standard group member with content creation and participation rights.

**Assignment:**
- Default role when joining public group
- Assigned after join request approved
- Most common group role

**Permissions:**

**Content Creation:**
- ✅ Create posts in group feed
- ✅ Post in group channels (if allowed by channel settings)
- ✅ Upload videos to group video channels (if allowed)
- ✅ Comment on group content
- ✅ React to posts and messages

**Participation:**
- ✅ View all public group content
- ✅ Participate in discussions
- ✅ Send messages in channels
- ✅ Join group live streams
- ✅ Interact with live stream chat

**Group Features:**
- ✅ View group member list
- ✅ Browse group channels
- ✅ Access group files and media
- ✅ Receive group notifications

**What MEMBER Cannot Do:**
- ❌ Moderate content
- ❌ Manage other members
- ❌ Change group settings
- ❌ Create channels
- ❌ Access admin features

**Authority:** Level 2 in group hierarchy.

---

### GUEST

**Description:** Limited access for visitors or prospective members.

**Assignment:**
- Manually assigned by GROUP_ADMIN for special cases
- Used for temporary or limited access

**Permissions:**

**View-Only Access:**
- ✅ View public group content
- ✅ Browse group feed (read-only)
- ✅ View group channels (read-only)
- ❌ Cannot post or comment
- ❌ Cannot upload content
- ❌ Cannot participate in chat
- ❌ Limited to viewing only

**Typical Use Cases:**
- Trial access before joining
- External observers
- Restricted access scenarios

**Authority:** Level 1 in group hierarchy (lowest).

---

## Permission System

### Global Permission Categories

**User Management** (`users.*`)
- users.view
- users.create
- users.update
- users.delete
- users.suspend
- users.ban
- users.reset_password

**Role Management** (`roles.*`)
- roles.view
- roles.assign
- roles.update

**Group Management** (`groups.*`)
- groups.view
- groups.create
- groups.update
- groups.delete
- groups.approve
- groups.manage_members
- groups.suspend

**Channel Management** (`channels.*`)
- channels.view
- channels.create
- channels.update
- channels.delete
- channels.manage_members

**Media Management** (`media.*`)
- media.view
- media.upload
- media.update
- media.delete
- media.moderate

**Video Management** (`videos.*`)
- videos.view
- videos.update
- videos.delete
- videos.moderate

**Reports & Moderation** (`reports.*, spam.*`)
- reports.view
- reports.review
- reports.resolve
- reports.dismiss
- spam.view
- spam.review
- spam.block
- spam.unblock

**Chat & Messaging** (`chat.*, messages.*`)
- chat.view
- chat.moderate
- chat.delete
- chat.manage_reports
- messages.send
- messages.read
- messages.pin
- messages.delete_everyone
- messages.announce

**Live Streaming** (`live.*, streams.*`)
- live.view
- live.manage
- live.moderate
- live.stop
- streams.start
- streams.end

**Notifications** (`notifications.*`)
- notifications.view
- notifications.send
- notifications.manage

**System** (`system.*, storage.*, audit.*`)
- system.view
- system.manage
- system.settings
- storage.view
- storage.manage
- audit.view

**User-Facing** (`profile.*, posts.*, comments.*, stories.*, reels.*, uploads.*, analytics.*`)
- profile.read
- profile.update
- posts.create
- posts.update
- posts.delete
- comments.create
- comments.delete
- stories.create
- stories.delete
- reels.create
- reels.delete
- uploads.create
- uploads.delete
- analytics.read

### Permission Hierarchy

**Authorization Flow:**
1. **SUPER_ADMIN check** - If role is SUPER_ADMIN, grant access immediately (wildcard bypass)
2. **Global role check** - Verify user's platform role matches required role(s)
3. **Permission check** - Verify user's role has required permission(s)
4. **Group role check** - If group context, verify user's group membership and role
5. **Custom authorization** - Additional business logic if needed

**Guard Execution Order:**
1. JwtAuthGuard - Validates authentication token
2. RolesGuard - Checks global role requirements (@Roles decorator)
3. PermissionsGuard - Checks specific permissions (@Permissions decorator)
4. GroupMembershipGuard - Checks group role requirements (@GroupRoles decorator)

---

## Role Comparison Table

### Platform-Wide Capabilities

| Capability | USER | SUPPORT | MODERATOR | ADMIN | SUPER_ADMIN |
|------------|------|---------|-----------|-------|-------------|
| Create content | ✅ | ✅ | ✅ | ✅ | ✅ |
| View reports | ❌ | ✅ | ✅ | ✅ | ✅ |
| Resolve reports | ❌ | ✅ | ✅ | ✅ | ✅ |
| Moderate content | ❌ | ❌ | ✅ | ✅ | ✅ |
| Approve groups | ❌ | ❌ | ✅ | ✅ | ✅ |
| Manage users | ❌ | ❌ | ❌ | ✅ | ✅ |
| Assign roles | ❌ | ❌ | ❌ | ✅ | ✅ |
| System settings | ❌ | ❌ | ❌ | ❌ | ✅ |
| View audit logs | ❌ | ❌ | ❌ | ✅ | ✅ |
| Ban users | ❌ | ❌ | ❌ | ✅ | ✅ |
| Stop live streams | ❌ | ❌ | ✅ | ✅ | ✅ |

### Group-Level Capabilities

| Capability | GUEST | MEMBER | MODERATOR | GROUP_ADMIN |
|------------|-------|--------|-----------|-------------|
| View content | ✅ | ✅ | ✅ | ✅ |
| Post content | ❌ | ✅ | ✅ | ✅ |
| Comment | ❌ | ✅ | ✅ | ✅ |
| Upload videos | ❌ | ✅ | ✅ | ✅ |
| Moderate content | ❌ | ❌ | ✅ | ✅ |
| Delete posts | ❌ | Own only | Any | Any |
| Manage members | ❌ | ❌ | ❌ | ✅ |
| Create channels | ❌ | ❌ | ❌ | ✅ |
| Assign roles | ❌ | ❌ | ❌ | ✅ |
| Edit group settings | ❌ | ❌ | ❌ | ✅ |
| Delete group | ❌ | ❌ | ❌ | ✅ |

---

## Common Scenarios

### Scenario 1: User Wants to Upload Video

**Requirements:**
- Must have `uploads.create` permission (granted to USER role)
- Must be member of a group with video channel
- Group role must allow video uploads (typically MEMBER or higher)

**Authorization Flow:**
1. Check user is authenticated (JwtAuthGuard)
2. Verify user has USER role or higher (all roles have this)
3. Check user is member of target group (GroupMembershipGuard)
4. Verify group role is MEMBER or higher
5. Check video channel upload permissions

**Result:** Any logged-in user who is a group member can upload videos.

---

### Scenario 2: Moderator Wants to Delete Inappropriate Post

**Requirements:**
- Must have MODERATOR role or higher
- Must have `posts.delete` or content moderation permission
- Post must be in their moderation scope

**Authorization Flow:**
1. Check user is authenticated
2. Verify role is MODERATOR, ADMIN, or SUPER_ADMIN (RolesGuard)
3. Verify has content moderation permission (PermissionsGuard)
4. Validate moderator can access this content
5. Log moderation action in audit log

**Result:** MODERATOR can delete the post.

---

### Scenario 3: User Wants to Start Live Stream

**Requirements:**
- Must have USER role (minimum)
- Must have `streams.start` permission
- Must be member of group with video channel
- Group role must allow streaming (MEMBER or higher)

**Authorization Flow:**
1. Check user is authenticated
2. Verify has `streams.start` permission (USER role has this)
3. Check group membership and role
4. Verify video channel exists and user has access
5. Provision Cloudinary live stream
6. Return stream key

**Result:** Group members can start live streams.

---

### Scenario 4: Admin Wants to Ban Problematic User

**Requirements:**
- Must have ADMIN or SUPER_ADMIN role
- Must have `users.ban` permission

**Authorization Flow:**
1. Check user is authenticated
2. Verify role is ADMIN or SUPER_ADMIN (RolesGuard)
3. Verify has `users.ban` permission (PermissionsGuard)
4. Cannot ban another ADMIN or SUPER_ADMIN (business logic)
5. Execute ban, revoke all sessions
6. Log action in audit log with reason

**Result:** Admin bans user, account status set to BANNED.

---

### Scenario 5: GROUP_ADMIN Wants to Remove Member

**Requirements:**
- Must be GROUP_ADMIN in that specific group
- Target member must not be GROUP_ADMIN (cannot remove other admins)

**Authorization Flow:**
1. Check user is authenticated
2. Verify user is member of the group
3. Check group role is GROUP_ADMIN (GroupMembershipGuard with @GroupRoles(GROUP_ADMIN))
4. Verify target is not another GROUP_ADMIN
5. Remove member, set `removedAt` timestamp

**Result:** Member removed from group.

---

### Scenario 6: Support Agent Resolves Report

**Requirements:**
- Must have SUPPORT role or higher
- Must have `reports.resolve` permission

**Authorization Flow:**
1. Check user is authenticated
2. Verify role is SUPPORT, MODERATOR, ADMIN, or SUPER_ADMIN
3. Verify has `reports.resolve` permission
4. Validate report exists and is pending
5. Mark report as resolved
6. Log action

**Result:** Report marked resolved, reporter notified.

---

## Best Practices

### For Platform Administrators

**Role Assignment:**
- Use minimum privilege principle
- Grant SUPER_ADMIN sparingly (only to trusted system administrators)
- Use ADMIN for day-to-day administration
- Assign MODERATOR to community managers
- Keep SUPPORT for customer service team

**Permission Management:**
- Regularly review role assignments
- Audit ADMIN and SUPER_ADMIN actions
- Document why each user has elevated permissions
- Remove permissions when no longer needed

**Security:**
- Enable additional authentication for ADMIN+ accounts
- Log all administrative actions
- Review audit logs weekly
- Rotate SUPER_ADMIN accounts periodically

### For Group Administrators

**Role Assignment:**
- Promote trusted members to MODERATOR gradually
- Grant GROUP_ADMIN to co-founders only
- Use GUEST role for trial periods
- Remove inactive moderators

**Moderation:**
- Establish clear community guidelines
- Train moderators on policies
- Escalate serious issues to platform ADMIN
- Document moderation decisions

**Member Management:**
- Welcome new members with group introduction
- Explain group rules clearly
- Use role promotions as recognition
- Regularly review member list

---

## Frequently Asked Questions

**Q: Can a USER be promoted to ADMIN directly?**
A: Yes, but only by an existing ADMIN or SUPER_ADMIN using the role assignment functionality.

**Q: What happens if someone has ADMIN role but is only MEMBER in a group?**
A: Platform ADMIN role bypasses group role checks. ADMIN can perform any action in any group regardless of their group role.

**Q: Can a GROUP_ADMIN remove another GROUP_ADMIN?**
A: No. Only the group creator or platform ADMIN can remove GROUP_ADMIN roles.

**Q: Do MODERATORS see all content platform-wide?**
A: Yes, MODERATOR role has access to all content for moderation purposes, regardless of privacy settings.

**Q: What if SUPER_ADMIN and GROUP_ADMIN conflict?**
A: SUPER_ADMIN always wins. Platform roles override group roles.

**Q: Can I have multiple roles?**
A: You have one global role (USER, SUPPORT, MODERATOR, ADMIN, or SUPER_ADMIN) and one role per group (GUEST, MEMBER, MODERATOR, or GROUP_ADMIN).

**Q: How do I request a role change?**
A: Contact platform support for global role changes. For group roles, contact your GROUP_ADMIN.

---

*Last updated: September 2026 - Based on verified implementation audit*
