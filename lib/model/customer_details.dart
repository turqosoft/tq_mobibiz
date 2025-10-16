class CustomerDetails {
    CustomerDetails({
        required this.data,
    });

    final Data? data;

    factory CustomerDetails.fromJson(Map<String, dynamic> json){ 
        return CustomerDetails(
            data: json["data"] == null ? null : Data.fromJson(json["data"]),
        );
    }

}

class Data {
    Data({
        required this.name,
        required this.owner,
        required this.creation,
        required this.modified,
        required this.modifiedBy,
        required this.docstatus,
        required this.idx,
        required this.enabled,
        required this.email,
        required this.firstName,
        required this.fullName,
        required this.username,
        required this.language,
        required this.timeZone,
        required this.sendWelcomeEmail,
        required this.unsubscribed,
        required this.roleProfileName,
        required this.muteSounds,
        required this.deskTheme,
        required this.newPassword,
        required this.logoutAllSessions,
        required this.resetPasswordKey,
        required this.lastResetPasswordKeyGeneratedOn,
        required this.documentFollowNotify,
        required this.documentFollowFrequency,
        required this.followCreatedDocuments,
        required this.followCommentedDocuments,
        required this.followLikedDocuments,
        required this.followAssignedDocuments,
        required this.followSharedDocuments,
        required this.threadNotify,
        required this.sendMeACopy,
        required this.allowedInMentions,
        required this.simultaneousSessions,
        required this.lastIp,
        required this.loginAfter,
        required this.userType,
        required this.lastActive,
        required this.loginBefore,
        required this.bypassRestrictIpCheckIf2FaEnabled,
        required this.lastLogin,
        required this.apiKey,
        required this.apiSecret,
        required this.onboardingStatus,
        required this.doctype,
        required this.defaults,
        required this.userEmails,
        required this.blockModules,
        required this.socialLogins,
        required this.roles,
    });

    final String? name;
    final String? owner;
    final DateTime? creation;
    final DateTime? modified;
    final String? modifiedBy;
    final int? docstatus;
    final int? idx;
    final int? enabled;
    final String? email;
    final String? firstName;
    final String? fullName;
    final String? username;
    final String? language;
    final String? timeZone;
    final int? sendWelcomeEmail;
    final int? unsubscribed;
    final String? roleProfileName;
    final int? muteSounds;
    final String? deskTheme;
    final String? newPassword;
    final int? logoutAllSessions;
    final String? resetPasswordKey;
    final DateTime? lastResetPasswordKeyGeneratedOn;
    final int? documentFollowNotify;
    final String? documentFollowFrequency;
    final int? followCreatedDocuments;
    final int? followCommentedDocuments;
    final int? followLikedDocuments;
    final int? followAssignedDocuments;
    final int? followSharedDocuments;
    final int? threadNotify;
    final int? sendMeACopy;
    final int? allowedInMentions;
    final int? simultaneousSessions;
    final String? lastIp;
    final int? loginAfter;
    final String? userType;
    final DateTime? lastActive;
    final int? loginBefore;
    final int? bypassRestrictIpCheckIf2FaEnabled;
    final DateTime? lastLogin;
    final String? apiKey;
    final String? apiSecret;
    final String? onboardingStatus;
    final String? doctype;
    final List<dynamic> defaults;
    final List<dynamic> userEmails;
    final List<dynamic> blockModules;
    final List<Role> socialLogins;
    final List<Role> roles;

    factory Data.fromJson(Map<String, dynamic> json){ 
        return Data(
            name: json["name"],
            owner: json["owner"],
            creation: DateTime.tryParse(json["creation"] ?? ""),
            modified: DateTime.tryParse(json["modified"] ?? ""),
            modifiedBy: json["modified_by"],
            docstatus: json["docstatus"],
            idx: json["idx"],
            enabled: json["enabled"],
            email: json["email"],
            firstName: json["first_name"],
            fullName: json["full_name"],
            username: json["username"],
            language: json["language"],
            timeZone: json["time_zone"],
            sendWelcomeEmail: json["send_welcome_email"],
            unsubscribed: json["unsubscribed"],
            roleProfileName: json["role_profile_name"],
            muteSounds: json["mute_sounds"],
            deskTheme: json["desk_theme"],
            newPassword: json["new_password"],
            logoutAllSessions: json["logout_all_sessions"],
            resetPasswordKey: json["reset_password_key"],
            lastResetPasswordKeyGeneratedOn: DateTime.tryParse(json["last_reset_password_key_generated_on"] ?? ""),
            documentFollowNotify: json["document_follow_notify"],
            documentFollowFrequency: json["document_follow_frequency"],
            followCreatedDocuments: json["follow_created_documents"],
            followCommentedDocuments: json["follow_commented_documents"],
            followLikedDocuments: json["follow_liked_documents"],
            followAssignedDocuments: json["follow_assigned_documents"],
            followSharedDocuments: json["follow_shared_documents"],
            threadNotify: json["thread_notify"],
            sendMeACopy: json["send_me_a_copy"],
            allowedInMentions: json["allowed_in_mentions"],
            simultaneousSessions: json["simultaneous_sessions"],
            lastIp: json["last_ip"],
            loginAfter: json["login_after"],
            userType: json["user_type"],
            lastActive: DateTime.tryParse(json["last_active"] ?? ""),
            loginBefore: json["login_before"],
            bypassRestrictIpCheckIf2FaEnabled: json["bypass_restrict_ip_check_if_2fa_enabled"],
            lastLogin: DateTime.tryParse(json["last_login"] ?? ""),
            apiKey: json["api_key"],
            apiSecret: json["api_secret"],
            onboardingStatus: json["onboarding_status"],
            doctype: json["doctype"],
            defaults: json["defaults"] == null ? [] : List<dynamic>.from(json["defaults"]!.map((x) => x)),
            userEmails: json["user_emails"] == null ? [] : List<dynamic>.from(json["user_emails"]!.map((x) => x)),
            blockModules: json["block_modules"] == null ? [] : List<dynamic>.from(json["block_modules"]!.map((x) => x)),
            socialLogins: json["social_logins"] == null ? [] : List<Role>.from(json["social_logins"]!.map((x) => Role.fromJson(x))),
            roles: json["roles"] == null ? [] : List<Role>.from(json["roles"]!.map((x) => Role.fromJson(x))),
        );
    }

}

class Role {
    Role({
        required this.name,
        required this.creation,
        required this.modified,
        required this.modifiedBy,
        required this.docstatus,
        required this.idx,
        required this.role,
        required this.parent,
        required this.parentfield,
        required this.parenttype,
        required this.doctype,
        required this.owner,
        required this.provider,
        required this.userid,
    });

    final String? name;
    final DateTime? creation;
    final DateTime? modified;
    final String? modifiedBy;
    final int? docstatus;
    final int? idx;
    final String? role;
    final String? parent;
    final String? parentfield;
    final String? parenttype;
    final String? doctype;
    final String? owner;
    final String? provider;
    final String? userid;

    factory Role.fromJson(Map<String, dynamic> json){ 
        return Role(
            name: json["name"],
            creation: DateTime.tryParse(json["creation"] ?? ""),
            modified: DateTime.tryParse(json["modified"] ?? ""),
            modifiedBy: json["modified_by"],
            docstatus: json["docstatus"],
            idx: json["idx"],
            role: json["role"],
            parent: json["parent"],
            parentfield: json["parentfield"],
            parenttype: json["parenttype"],
            doctype: json["doctype"],
            owner: json["owner"],
            provider: json["provider"],
            userid: json["userid"],
        );
    }

}
