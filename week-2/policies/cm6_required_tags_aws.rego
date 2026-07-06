# METADATA
# title: CM-6 - Configuration Settings (AWS required tags)
# description: Taggable resources must carry the four required compliance tags.
# custom:
#   control_id: CM-6
#   framework: nist-800-53
#   severity: medium
#   remediation: Add the missing tags or rely on provider default_tags.
package compliance.cm6_aws

import rego.v1

required := {"Project", "Environment", "ManagedBy", "ComplianceScope"}

# Deny a resource for each required tag it is missing. Resources with no
# tags_all (i.e. not taggable) are skipped because the lookup is undefined.
deny contains msg if {
	some resource in input.planned_values.root_module.resources
	tags := resource.values.tags_all
	some tag in required
	not tags[tag]
	msg := sprintf("CM-6: %s is missing required tag %q. Remediation: add the missing tag or rely on the provider default_tags block.", [resource.address, tag])
}
