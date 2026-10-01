# Infrastructure Code Conventions

## Module structure and ownership

- Build small, focused modules around a service or resource responsibility.
- A module may own several tightly coupled resource types that form one coherent service.
- Use child modules for coupled responsibilities with a clear ownership boundary. Parents coordinate their children and expose their outputs; the root coordinates services.
- Name resources and data sources `this`. When multiple instances of the same resource type are needed, use separate module instances with descriptive names.
- Keep modules straightforward. Avoid generic frameworks, speculative abstractions and wrappers that merely rename provider functionality.
- Use native HCL for infrastructure declarations. Include service-required scripts only where necessary.

## Composition and iteration

- Put collection iteration in the root by default. Each leaf module manages one instance.
- Use `for_each` keyed by stable, meaningful identifiers rather than list indexes.
- Keep singleton resources independent of collections that may be empty.
- A narrowly scoped exception may allow a parent module to iterate children it directly owns. Keep that ownership explicit; each child module still manages one instance.
- Treat changes to iteration keys as resource-address changes. Reordering inputs should preserve addresses; removing entries does not mean preserving their resources.

## Inputs and outputs

- Group correlated configuration in explicitly typed objects at the root.
- Pass scalar values and primitive lists across module boundaries by default. Do not pass entire root configuration objects into service modules.
- Where a parent explicitly owns a child collection, it may accept typed child definitions and pass individual scalar fields to each child.
- Use short, useful variable descriptions.
- Do not add variable-validation blocks or HCL tests.
- Require explicit inputs for owner-selected names, policies and environment settings. Avoid hidden defaults or inference from collection size or ordering.
- Let optional overrides defer to provider or service defaults when omitted. Omit optional nested blocks when their configuration is absent.
- Expose outputs needed by callers. Aggregate related values at the root, and expose owned child identifiers as maps keyed by stable names.
- Connect dependencies through resource and module outputs.

## File organization and providers

- Small modules may keep variables, locals, resources or child modules, and outputs together in `main.tf`, in that order.
- Split files when size or readability warrants it. Provider requirements may live in `versions.tf`.
- Keep Terraform/OpenTofu requirements and backend configuration at the beginning of the root configuration, followed by provider configurations.
- Configure one default provider instance per provider at the root. Child modules declare requirements and inherit configuration.
- Do not introduce provider aliases or configure providers inside child modules.
- Perform shared prerequisite lookups at the root and pass their identifiers to consumers.
- Keep provider credentials separate from resource configuration, using the provider's standard credential resolution.

## Environments and state

- Invoke the same root and modules separately for each environment.
- Require an explicit scalar `environment` input without a default. Do not use workspace selection or inferred environment lookups.
- Supply complete resource names, hostnames, prefixes and state locations explicitly. Pass them unchanged; do not derive them from `environment`.
- Keep state independent for each environment. Do not manage the same remote resource from multiple states.
- Keep backend configuration in the root and supply each environment's backend settings explicitly.
- Merge tags so the lowercase `environment` tag overrides any caller-supplied value.
- Treat state storage and other externally owned prerequisites as existing infrastructure unless provisioning them is explicitly in scope.
- Reconfigure backend selection when switching environments; do not migrate or copy state between environments.

## Change discipline and verification

- Follow the nearest existing implementation and preserve unrelated changes.
- Preserve existing resource addresses unless an address change is intentional and its migration is separately planned.
- Keep local inputs and credential files ignored. Commit only safe examples and placeholders.
- Run CI with complete environment-specific inputs in a clean checkout.
- Keep secrets out of source, logs and outputs.
- Run formatting and static checks proportionate to the change. Do not claim that static checks establish live behavior.
- Code preparation does not authorize initialization, planning, imports, state moves, provisioning or deployment. Perform those operations only within the explicitly authorized scope.
- Generate provider lockfile changes through authorized initialization; never invent checksums.