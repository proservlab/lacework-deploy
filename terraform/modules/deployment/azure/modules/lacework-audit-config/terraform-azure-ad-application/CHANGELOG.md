# v2.0.1

## Other Changes
* ci: version bump to v2.0.1-dev (Lacework)([e353816](https://github.com/lacework/terraform-azure-ad-application/commit/e353816cab87f764f686310fb6613257faf9ba09))
---
# v2.0.0
## Refactor
* refactor: Upgrade azureAD to 3.X.

## Other Changes
* chore(GROW-2952): add codeowners (#57) (Matt Cadorette)([356a04d](https://github.com/lacework/terraform-azure-ad-application/commit/356a04d982415223885df6ed1b56f2b0f8970e32))
* chore: set local var module name (#54) (Darren)([27af345](https://github.com/lacework/terraform-azure-ad-application/commit/27af3455eb6185af5b06424fcda56b25affea444))
* ci: migrate from codefresh to github actions (#56) (Timothy MacDonald)([aaab6d5](https://github.com/lacework/terraform-azure-ad-application/commit/aaab6d5e490ad219b33e7f8ef22edc0e73f39c82))
* ci: version bump to v1.3.2-dev (Lacework)([23959af](https://github.com/lacework/terraform-azure-ad-application/commit/23959afd2438ef26af9833db9513a834f6a3438c))
---
# v1.3.1

## Documentation Updates
* docs(readme): add terraform docs automation (#51) (Timothy MacDonald)([0fd4a3e](https://github.com/lacework/terraform-azure-ad-application/commit/0fd4a3ec06f3724d9cff69218925c8abb3a1aee9))
## Other Changes
* chore: add lacework_metric_module datasource (#52) (Darren)([6caa724](https://github.com/lacework/terraform-azure-ad-application/commit/6caa72403ab4f79ea560c4227196bd893091e410))
* ci: tfsec (jon-stewart)([6bd68c3](https://github.com/lacework/terraform-azure-ad-application/commit/6bd68c3b6348ff815c2b82c44f05cd242924fd43))
* ci: version bump to v1.3.1-dev (Lacework)([af405da](https://github.com/lacework/terraform-azure-ad-application/commit/af405daa43307c31395eda59a95b62036252d624))
---
# v1.3.0

## Features
* feat: Set owner for service principal (#47) (NolanT)([d07c25e](https://github.com/lacework/terraform-azure-ad-application/commit/d07c25e4a427ce0f3c324159bc3f380bf5dc7873))
## Other Changes
* ci: version bump to v1.2.2-dev (Lacework)([30f50e3](https://github.com/lacework/terraform-azure-ad-application/commit/30f50e3d0ec2a5546123fe1c02df4c65d27adc45))
---
# v1.2.1

## Bug Fixes
* fix: upgrade issue from v1.1.0 -> v1.2.0 (#45) (Darren)([aff3fff](https://github.com/lacework/terraform-azure-ad-application/commit/aff3fff9c74e91e938a6e41636171b9a670725ac))
## Other Changes
* ci: version bump to v1.2.1-dev (Lacework)([16d4aa9](https://github.com/lacework/terraform-azure-ad-application/commit/16d4aa9663b110a3a80e4a3f2923082416568a6e))
---
# v1.2.0

## Features
* feat: deprecate support for Terraform 0.12 and 0.13 (Darren Murray)([9f5311d](https://github.com/lacework/terraform-azure-ad-application/commit/9f5311d5e325b590d6933872d8d0c22275f638a3))
## Bug Fixes
* fix(deps): updating azuread and migrating from deprecated resource (#40) (Alan Nix)([ecead47](https://github.com/lacework/terraform-azure-ad-application/commit/ecead477b1423609d571bfda3b54a77f26f67742))
## Other Changes
* ci: version bump to v1.1.1-dev (Lacework)([d2908bd](https://github.com/lacework/terraform-azure-ad-application/commit/d2908bd1f7f841832fcad9a7b7e67b960336c9d4))
---
# v1.1.0

## Features
* feat: Add variable to override AD Application owners (#35) (cgraf-spiria)([19b12e6](https://github.com/lacework/terraform-azure-ad-application/commit/19b12e6b517c4f1dec4760023907952942b0f57d))
## Documentation Updates
* docs: be explicit about where inputs got moved (#36) (Salim Afiune)([ff13b48](https://github.com/lacework/terraform-azure-ad-application/commit/ff13b48d553be37d575fdfd1027e9d03a4d23e82))
## Other Changes
* ci: version bump to v1.0.1-dev (Lacework)([5aac26a](https://github.com/lacework/terraform-azure-ad-application/commit/5aac26a8fbce6885bc63d37afbd3049f3f69ab74))
---
# v1.0.0

## Refactor
* refactor: update examples and format code for release (#31) (Salim Afiune)([17d1bef](https://github.com/lacework/terraform-azure-ad-application/commit/17d1bef1c5161f9c309198237d988c87e85c1843))
* refactor: use Directory Reader AD role instead of API (#28) (Marc Garcia)([69fd49c](https://github.com/lacework/terraform-azure-ad-application/commit/69fd49c90eb667231a45705c1925e60de84dcbdf))
* refactor: remove Reader permissions from AD app and unbundle azurerm stuff (#26) (Marc Garcia)([6a38bc1](https://github.com/lacework/terraform-azure-ad-application/commit/6a38bc1a2174667904b1ddb9163713c5c5ec1d04))
## Documentation Updates
* docs: Fix typo (Darren)([11da0b1](https://github.com/lacework/terraform-azure-ad-application/commit/11da0b1fbdafc1a47e8a3736feae62cc77d38081))
* docs: Address code review comments (Darren Murray)([4a3e66f](https://github.com/lacework/terraform-azure-ad-application/commit/4a3e66fe637591424f9199b84751ac7e57d079e8))
* docs: Add contributing documentation (Darren Murray)([e7a3b31](https://github.com/lacework/terraform-azure-ad-application/commit/e7a3b31a2fb2a18ce1fac1b539562cafced0b006))
## Other Changes
* chore: version bump to v0.2.3-dev (Lacework)([aa984bb](https://github.com/lacework/terraform-azure-ad-application/commit/aa984bb4469995cc5cca64430c0d9278714884d3))
* ci: sign lacework-releng commits (#21) (Salim Afiune)([2f137a5](https://github.com/lacework/terraform-azure-ad-application/commit/2f137a51127440727c3b588974ffdb9b4d9cbc76))
---
# v0.2.2

## Bug Fixes
* fix(deps): upgrade min azurerm version to ~> 2.28 (#19) (Salim Afiune)([e528d18](https://github.com/lacework/terraform-azure-ad-application/commit/e528d18db2564fbd5b38b55130aff0aa075f74bf))
## Other Changes
* chore: version bump to v0.2.2-dev (Lacework)([b3dbb1b](https://github.com/lacework/terraform-azure-ad-application/commit/b3dbb1bca79498a48f26aa11cc0bc0062a20dbfa))
---
# v0.2.1

## Bug Fixes
* fix: updating to proper `azuread` provider version (#17) (Alan Nix)([d6a1452](https://github.com/lacework/terraform-azure-ad-application/commit/d6a14529389b0268e2768b81dd8f2c2f0e693e19))
## Other Changes
* chore: version bump to v0.2.1-dev (Lacework)([f6c0930](https://github.com/lacework/terraform-azure-ad-application/commit/f6c09305f2f8f859c2c8c475ff81f75b36aef43d))
---
# v0.2.0

## Features
* feat: allow the use of management groups to assign permissions (Alan Nix)([ddf2a87](https://github.com/lacework/terraform-azure-ad-application/commit/ddf2a876d42c74a6b1e2c17eb7f10d475910af48))
## Documentation Updates
* docs: updated pessimistic constraint on module version (Alan Nix)([62ce296](https://github.com/lacework/terraform-azure-ad-application/commit/62ce296cc13848ba067527a372464d71ed82a014))
## Other Changes
* chore: removed usage of deprecated inputs (Alan Nix)([1fb3d6f](https://github.com/lacework/terraform-azure-ad-application/commit/1fb3d6f0425191afc13fa1f92d673480582a3acb))
* chore: version bump to v0.1.5-dev (Lacework)([aa2daf8](https://github.com/lacework/terraform-azure-ad-application/commit/aa2daf87d5541a7d89665644eb7817c9b28183dc))
---
# v0.1.4

## Other Changes
* chore: bump required version of terraform to 0.12.31 (#12) (Scott Ford)([b138bdb](https://github.com/lacework/terraform-azure-ad-application/commit/b138bdb63a226565616e11d6054ffb465814dbf3))
* ci: fix finding major versions during release (#11) (Salim Afiune)([096acd8](https://github.com/lacework/terraform-azure-ad-application/commit/096acd83e39b3355d5182e285ddfb865b5ff4121))
* ci: switch PR test from CircleCI to CodeFresh (#10) (Darren)([5026f00](https://github.com/lacework/terraform-azure-ad-application/commit/5026f00995dc1ccbbcea466b1499e9dd25758eb8))
* ci: switch releases to be own by Lacework releng ⚡ (#9) (Salim Afiune)([7e6ea42](https://github.com/lacework/terraform-azure-ad-application/commit/7e6ea42545326cb59a8e32533d724f4d44268007))
---
# v0.1.3

## Documentation Updates
* docs: Update examples with README files (#7) (Scott Ford)([2cf3115](https://github.com/lacework/terraform-azure-ad-application/commit/2cf3115030c643c19b0351f30ceb9da10156140b))
## Other Changes
* ci: send slack notifications to team alias ⭐ (#6) (Salim Afiune)([e7751ad](https://github.com/lacework/terraform-azure-ad-application/commit/e7751ad32e79dfcc344e3cc72a40da5e02301886))
---
# v0.1.2

## Other Changes
* ci: update release notes generation (Salim Afiune Maya)([274cc2e](https://github.com/lacework/terraform-azure-ad-application/commit/274cc2e015728f7ccc631f137125e1f56cd5342c))
* ci: fix release script.sh (#3) (Salim Afiune)([4723236](https://github.com/lacework/terraform-azure-ad-application/commit/4723236a3c6ca10b0bc7ac07a9a90c1541db6f42))
---
# v0.1.1

## Bug Fixes
* fix(variables): Removed default identifier URI (Alan Nix)([1feaeb7](https://github.com/lacework/terraform-aure-ad-application/commit/1feaeb72e21b708ae3cd40532a22e2baa71f639b))
## Other Changes
* ci: fix scripts (Salim Afiune Maya)([ccbf348](https://github.com/lacework/terraform-aure-ad-application/commit/ccbf348499b79769c6b1ea19dca7de7c56b82c67))
---
# v0.1.0

🌈 Initial commit
