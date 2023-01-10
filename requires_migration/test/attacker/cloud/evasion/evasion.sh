# a.entity_type = 'api' AND
#         (
#             (
#                 a.service = 'fms.amazonaws.com' AND
#                 a.api IN [
#                     'DeletePolicy',
#                     'DeleteProtocolsList',
#                     'PutPolicy',
#                     'PutProtocolsList'
#                 ]
#             ) OR (
#                 a.service = 'guardduty.amazonaws.com' AND
#                 a.api IN [
#                     'DeleteDetector',
#                     'DeleteFilter',
#                     'DeleteIPSet',
#                     'DeleteMembers',
#                     'DeleteThreatIntelSet',
#                     'UpdateIPSet',
#                     'UpdateFilter',
#                     'UpdateMemberDetectors',
#                     'UpdateThreatIntelSet'
#                 ]
#             ) OR (
#                 a.service = 'inspector.amazonaws.com' AND
#                 a.api IN [
#                     'DeleteAssessmentRun',
#                     'DeleteAssessmentTarget',
#                     'DeleteAssessmentTemplate',
#                     'StopAssessmentRun'
#                 ]
#             ) OR (
#                 a.service = 'network-firewall.amazonaws.com' AND
#                 a.api IN [
#                     'DeleteFirewall',
#                     'DeleteFirewallPolicy',
#                     'DeleteResourcePolicy',
#                     'DeleteRuleGroup',
#                     'UpdateFirewallDeleteProtection',
#                     'UpdateFirewallPolicy',
#                     'UpdateFirewallPolicyChangeProtection',
#                     'UpdateLoggingConfiguration',
#                     'UpdateRuleGroup',
#                     'UpdateSubnetChangeProtection'
#                 ]
#             ) OR (
#                 a.service = 'waf.amazonaws.com' AND
#                 a.api =~ 'Delete.*'
#             ) OR (
#                 a.service = 'waf.amazonaws.com' AND
#                 a.api =~ 'Update.*'
#             )
#         )