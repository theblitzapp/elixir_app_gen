%Doctor.Config{
  exception_moduledoc_required: true,
  failed: false,
  ignore_modules: [
    AppGen.Support.Accounts.Label,
    AppGen.Support.Accounts.Role,
    AppGen.Support.Accounts.Team,
    AppGen.Support.Accounts.User,
    AppGen.Support.Accounts.TeamOrganization
  ],
  ignore_paths: [],
  min_module_doc_coverage: 0,
  min_module_spec_coverage: 0,
  min_overall_doc_coverage: 0,
  min_overall_spec_coverage: 0,
  min_overall_moduledoc_coverage: 0,
  raise: false,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  umbrella: false
}
