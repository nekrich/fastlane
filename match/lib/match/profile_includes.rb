require_relative 'portal_fetcher'
require_relative 'module'

module Match
  class ProfileIncludes
    PROV_TYPES_WITH_DEVICES = [:adhoc, :development]
    PROV_TYPES_WITH_MULTIPLE_CERTIFICATES = [:development]

    def self.can_force_include?(params:, notify:)
      self.can_force_include_all_devices?(params: params, notify: notify) &&
        self.can_force_include_new_certificates?(params: params)
    end

    ###############
    #
    # DEVICES
    #
    ###############

    def self.should_force_include_all_devices?(params:, portal_profile:, cached_devices:)
      return false unless self.can_force_include_all_devices?(params: params)

      force = devices_differ?(portal_profile: portal_profile, platform: params[:platform], include_mac_in_profiles: params[:include_mac_in_profiles], cached_devices: cached_devices)

      return force
    end

    def self.can_force_include_all_devices?(params:, notify: false)
      return false if params[:readonly] || params[:force]
      return false unless params[:force_for_new_devices]

      provisioning_type = params[:type].to_sym

      can_force = PROV_TYPES_WITH_DEVICES.include?(provisioning_type)

      if !can_force && notify
        # App Store provisioning profiles don't contain device identifiers and
        # thus shouldn't be renewed if the device count has changed.
        UI.important("Warning: `force_for_new_devices` is set but is ignored for #{provisioning_type}.")
        UI.important("You can safely stop specifying `force_for_new_devices` when running Match for type '#{provisioning_type}'.")
      end

      can_force
    end

    def self.devices_differ?(portal_profile:, platform:, include_mac_in_profiles:, cached_devices:)
      return false unless portal_profile

      profile_devices = portal_profile.devices || []

      portal_devices = cached_devices
      portal_devices ||= Match::Portal::Fetcher.devices(platform: platform, include_mac_in_profiles: include_mac_in_profiles)

      profile_device_ids = profile_devices.map(&:id).sort
      portal_devices_ids = portal_devices.map(&:id).sort

      devices_differs = profile_device_ids != portal_devices_ids

      UI.important("Devices in the profile and available on the portal differ. Recreating a profile") if devices_differs

      return devices_differs
    end

    ###############
    #
    # CERTIFICATES
    #
    ###############

    def self.should_force_include_new_certificates?(params:, portal_profile:, certificate_id:, cached_certificates:)
      return false unless self.can_force_include_new_certificates?(params: params)

      force = certificates_differ?(portal_profile: portal_profile, platform: params[:platform], certificate_id: certificate_id, cached_certificates: cached_certificates)

      return force
    end

    def self.can_force_include_new_certificates?(params:)
      return false if params[:readonly] || params[:force]
      return params[:force_for_new_certificates]
    end

    def self.certificates_differ?(portal_profile:, platform:, certificate_id:, cached_certificates:)
      return false unless portal_profile

      profile_certs = portal_profile.certificates || []

      portal_certs = cached_certificates
      portal_certs ||= Match::Portal::Fetcher.certificates(platform: platform, profile_type: portal_profile.profile_type)

      if certificate_id
        portal_certs.filter! { |c| c.id == certificate_id }
      end

      profile_certs_ids = profile_certs.map(&:id).sort
      portal_certs_ids = portal_certs.map(&:id).sort

      certificates_differ = profile_certs_ids != portal_certs_ids

      UI.important("Certificates in the profile and available on the portal differ. Recreating a profile") if certificates_differ

      return certificates_differ
    end
  end
end
