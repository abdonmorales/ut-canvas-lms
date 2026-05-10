# frozen_string_literal: true

# UT Austin self-host bootstrap tasks.
#
# Usage:
#   bundle exec rake ut:bootstrap
#
# Idempotent. Safe to re-run after upgrades to re-apply UT defaults if an
# admin overrode something through the UI by accident.

namespace :ut do
  desc "Apply UT Austin defaults to the root account (name, support links, help menu)"
  task bootstrap: :environment do
    account = Account.default.reload
    account.name = "The University of Texas at Austin"
    account.default_time_zone = "America/Chicago"
    account.default_locale = "en"

    account.settings[:help_link_name] = "UT Canvas Help"
    account.settings[:help_link_icon] = "help"
    account.settings[:custom_help_links] = [
      {
        "id" => "ut_service_desk",
        "type" => "custom",
        "text" => "UT Service Desk",
        "subtext" => "24/7 IT support for students, faculty, and staff",
        "url" => "https://ut.service-now.com/utss/",
        "available_to" => %w[user student teacher admin observer unenrolled]
      },
      {
        "id" => "canvas_status",
        "type" => "custom",
        "text" => "Canvas System Status",
        "subtext" => "Check current Canvas availability",
        "url" => "https://status.instructure.com/",
        "available_to" => %w[user student teacher admin observer unenrolled]
      },
      {
        "id" => "report_problem",
        "type" => "default",
        "text" => "Report a Problem",
        "subtext" => "If Canvas misbehaves, tell us what happened",
        "url" => "#create_ticket",
        "available_to" => %w[user student teacher admin observer unenrolled]
      },
      {
        "id" => "ut_eid",
        "type" => "custom",
        "text" => "Manage Your UT EID",
        "subtext" => "Update your UT EID password and account",
        "url" => "https://idmanager.its.utexas.edu/eid_self_help/",
        "available_to" => %w[user student teacher admin observer unenrolled]
      }
    ]

    account.save!
    puts "UT defaults applied to Account #{account.id} (#{account.name})."

    Rake::Task["ut:enable_features"].invoke
  end

  # Enables the comma-separated list of feature flags in UT_FEATURE_FLAGS.
  # No-op when the env var is unset, so this is safe to call from bootstrap.
  #
  # Example:
  #   UT_FEATURE_FLAGS=react_discussions_post,enhanced_rubrics \
  #     bundle exec rake ut:enable_features
  desc "Enable UT-selected Canvas feature flags on the root account"
  task enable_features: :environment do
    flags = (ENV["UT_FEATURE_FLAGS"] || "").split(",").map(&:strip).reject(&:empty?)
    if flags.empty?
      puts "UT_FEATURE_FLAGS not set; no feature flags enabled."
      next
    end

    account = Account.default.reload
    flags.each do |flag|
      account.enable_feature!(flag.to_sym)
      puts "Enabled feature flag: #{flag}"
    rescue => e
      warn "Could not enable feature flag #{flag}: #{e.message}"
    end
  end

  # ------------------------------------------------------------------
  # UT EID / CAS SSO — DEAD CODE
  # ------------------------------------------------------------------
  # NOT wired into bootstrap. This task exists so the configuration is
  # version-controlled and reviewable, but it MUST NOT be invoked until:
  #
  #   1. UT Identity Services has issued a service registration for this
  #      Canvas deployment (callback URL, allowed attributes).
  #   2. The endpoint values below have been confirmed against current
  #      Enterprise Authentication docs at:
  #        https://identity.utexas.edu/everyone/how-to-use-enterprise-authentication
  #   3. A staging environment has verified the EID -> Canvas user mapping.
  #
  # When ready, remove the early `abort` below and run:
  #   bundle exec rake ut:configure_cas
  desc "[DEAD CODE] Configure UT EID CAS authentication provider"
  task configure_cas: :environment do
    abort "ut:configure_cas is intentionally disabled. See lib/tasks/ut.rake before enabling."

    # rubocop:disable Lint/UnreachableCode
    account = Account.default.reload

    # Remove any stale CAS providers so this task is idempotent.
    account.authentication_providers.active.where(auth_type: "cas").destroy_all

    account.authentication_providers.create!(
      auth_type: "cas",
      auth_base: "https://login.utexas.edu/login/cas",
      # UT EID is the CAS principal. Canvas matches it against the
      # `unique_id` of a Pseudonym on the root account.
      login_attribute: "user",
      jit_provisioning: false
    )

    account.settings[:login_handle_name] = "UT EID"
    account.save!
    puts "CAS provider configured against login.utexas.edu."
    # rubocop:enable Lint/UnreachableCode
  end
end
