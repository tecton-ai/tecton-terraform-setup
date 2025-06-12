# Changelog

## [1.6.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.5.0...v1.6.0) (2025-06-12)


### Features

* Add tecton_outputs module to write shared values. ([#221](https://github.com/tecton-ai/tecton-terraform-setup/issues/221)) ([f4a3a47](https://github.com/tecton-ai/tecton-terraform-setup/commit/f4a3a47fdaf05859121f50e72e9f9d2f7abce7c7))

## [1.5.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.4.0...v1.5.0) (2025-06-10)


### Features

* Add option to extend allowed buckets (for read) for Rift Compute role ([#219](https://github.com/tecton-ai/tecton-terraform-setup/issues/219)) ([dd675e4](https://github.com/tecton-ai/tecton-terraform-setup/commit/dd675e496ce5ef5b0692a7d0f97be38073c05522))

## [1.4.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.3.0...v1.4.0) (2025-06-05)


### Features

* Add options for disabling direct cross-account bucket policy and limiting cross-account assumerole ([#216](https://github.com/tecton-ai/tecton-terraform-setup/issues/216)) ([72104dc](https://github.com/tecton-ai/tecton-terraform-setup/commit/72104dc9af10f016a429372c44103ead1d8069ee))


### Bug Fixes

* Set defaults to empty list for additional PL SG rules inputs. ([#217](https://github.com/tecton-ai/tecton-terraform-setup/issues/217)) ([0180afb](https://github.com/tecton-ai/tecton-terraform-setup/commit/0180afbf285b240bae3b84862b5656672312e94f))

## [1.3.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.2.0...v1.3.0) (2025-06-02)


### Features

* Support importing existing VPC into rift_compute module ([#210](https://github.com/tecton-ai/tecton-terraform-setup/issues/210)) ([3187d32](https://github.com/tecton-ai/tecton-terraform-setup/commit/3187d322c57fa372253d29b09101597b9283e8a1))

## [1.2.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.1.0...v1.2.0) (2025-05-28)


### Features

* Add dataplane_rift_with_emr module. ([#208](https://github.com/tecton-ai/tecton-terraform-setup/issues/208)) ([e6ea67d](https://github.com/tecton-ai/tecton-terraform-setup/commit/e6ea67dd9796159b18d169b131af41e63d465be9))

## [1.1.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.0.0...v1.1.0) (2025-05-23)


### Features

* add option to set tags for offline storage ([#53](https://github.com/tecton-ai/tecton-terraform-setup/issues/53)) ([d0f5254](https://github.com/tecton-ai/tecton-terraform-setup/commit/d0f52545768633c846eefa7d690453a31d9ec43c))
* Add permission change for customer repo ([#109](https://github.com/tecton-ai/tecton-terraform-setup/issues/109)) ([4b9f574](https://github.com/tecton-ai/tecton-terraform-setup/commit/4b9f574f5fa8f34e823b2f4ddfe7fe93a5b074a0))
* add rift example and tweaks ([#123](https://github.com/tecton-ai/tecton-terraform-setup/issues/123)) ([8183d3c](https://github.com/tecton-ai/tecton-terraform-setup/commit/8183d3c003273262f222e2a697b593e3958fe384))
* add support for customer managed kms key ([#107](https://github.com/tecton-ai/tecton-terraform-setup/issues/107)) ([8a6dae7](https://github.com/tecton-ai/tecton-terraform-setup/commit/8a6dae73ec4d9a5deb3997872479fc153913ef9c))
* add validation script ([#103](https://github.com/tecton-ai/tecton-terraform-setup/issues/103)) ([62883dc](https://github.com/tecton-ai/tecton-terraform-setup/commit/62883dcbd2509303449134f945159d40848480b4))
* allow EMR roles to pull ECR images ([#110](https://github.com/tecton-ai/tecton-terraform-setup/issues/110)) ([2a2e1ee](https://github.com/tecton-ai/tecton-terraform-setup/commit/2a2e1ee0826ad5d0c4cc0d10009d698655771bc9))
* Enable EMR notebook cluster logs access when debugging enabled  ([#57](https://github.com/tecton-ai/tecton-terraform-setup/issues/57)) ([77318d9](https://github.com/tecton-ai/tecton-terraform-setup/commit/77318d9174d7aab78318da919f6ac2b85e802b26))
* fine-grained S3 permissions ([#179](https://github.com/tecton-ai/tecton-terraform-setup/issues/179)) ([950c7df](https://github.com/tecton-ai/tecton-terraform-setup/commit/950c7df2dfdefb0697cfa667303fe2c849a249ae))
* fully support KMS on rift ([35b3c6b](https://github.com/tecton-ai/tecton-terraform-setup/commit/35b3c6b6065ef847be2d33e25f6bb8e26ecd22aa))
* privatelink-cross-vpc module ([#100](https://github.com/tecton-ai/tecton-terraform-setup/issues/100)) ([a2ab6ff](https://github.com/tecton-ai/tecton-terraform-setup/commit/a2ab6ff14c69cc04d77e21296c317a472307b988))
* reduce down the permissions required by Rift VM ([#147](https://github.com/tecton-ai/tecton-terraform-setup/issues/147)) ([b0813af](https://github.com/tecton-ai/tecton-terraform-setup/commit/b0813afeb2c1a980ad986df59f3c0657c093203a))
* s3 bucket policy to allow cross-account read-write access ([#120](https://github.com/tecton-ai/tecton-terraform-setup/issues/120)) ([a5b2826](https://github.com/tecton-ai/tecton-terraform-setup/commit/a5b282654929147ee28414a6c1850eb33f78eee6))
* separate flags controlling spark and rift iam resources [DVOPS-1809] ([#144](https://github.com/tecton-ai/tecton-terraform-setup/issues/144)) ([087e327](https://github.com/tecton-ai/tecton-terraform-setup/commit/087e327036179c7d7c702db2d86b997c6f335cc7))
* set bucket acl to BucketOwnerEnforced ([#51](https://github.com/tecton-ai/tecton-terraform-setup/issues/51)) ([006a177](https://github.com/tecton-ai/tecton-terraform-setup/commit/006a177e7491b3bf560576046800eceb607471e8))
* support AssumeRole into cross-account intermediate role ([#152](https://github.com/tecton-ai/tecton-terraform-setup/issues/152)) ([c2856e8](https://github.com/tecton-ai/tecton-terraform-setup/commit/c2856e8e04cd8eec76c90731bccc20fad17825f4))
* support rift_compute module and rift on dataplane [DVOPS-1808] ([#141](https://github.com/tecton-ai/tecton-terraform-setup/issues/141)) ([e469449](https://github.com/tecton-ai/tecton-terraform-setup/commit/e4694495d4494f8fb33887d0821df9414873c485))
* tighter s3 controls + emr/notebook init args ([#97](https://github.com/tecton-ai/tecton-terraform-setup/issues/97)) ([1299d3b](https://github.com/tecton-ai/tecton-terraform-setup/commit/1299d3bd86d2fcf26685ae2393fb9a859c5218f7))


### Bug Fixes

* add missing local variable ([#130](https://github.com/tecton-ai/tecton-terraform-setup/issues/130)) ([10d7928](https://github.com/tecton-ai/tecton-terraform-setup/commit/10d7928b924dc11d8ead418f90b123db14f4da0b))
* Give EMR spark role access to notebook cluster logs s3 bucket ([#58](https://github.com/tecton-ai/tecton-terraform-setup/issues/58)) ([1598e50](https://github.com/tecton-ai/tecton-terraform-setup/commit/1598e50b2a4d4754e95ef2375ab08d2a581177a8))
* Give issues(labelling) permission to release-please action, upgrade to v4 ([#205](https://github.com/tecton-ai/tecton-terraform-setup/issues/205)) ([88c4d43](https://github.com/tecton-ai/tecton-terraform-setup/commit/88c4d4391718d11b8562f4115fdb6bd06d587643))
* Remove ACL from the S3 bucket `tecton` ([#75](https://github.com/tecton-ai/tecton-terraform-setup/issues/75)) ([9fc8f31](https://github.com/tecton-ai/tecton-terraform-setup/commit/9fc8f31df82802519cc872a45280086d44b8928d))
* Remove warnings for S3 bucket server side encryption configuration & acl ([#74](https://github.com/tecton-ai/tecton-terraform-setup/issues/74)) ([71e12a0](https://github.com/tecton-ai/tecton-terraform-setup/commit/71e12a0b6a64ace605f88f9dbb9c671fd51bf500))
* typo ([#142](https://github.com/tecton-ai/tecton-terraform-setup/issues/142)) ([b8e094d](https://github.com/tecton-ai/tecton-terraform-setup/commit/b8e094d4b43890d332593aae5b034dfd4fb802d0))
* Update dynamo cross account role with new time to live roles ([#145](https://github.com/tecton-ai/tecton-terraform-setup/issues/145)) ([7ad35bc](https://github.com/tecton-ai/tecton-terraform-setup/commit/7ad35bcef2492d3c4fcaf618e8c6464dedf9943b))

## [1.1.0](https://github.com/tecton-ai/tecton-terraform-setup/compare/v1.0.0...v1.1.0) (2025-05-22)


### Features

* add option to set tags for offline storage ([#53](https://github.com/tecton-ai/tecton-terraform-setup/issues/53)) ([d0f5254](https://github.com/tecton-ai/tecton-terraform-setup/commit/d0f52545768633c846eefa7d690453a31d9ec43c))
* Add permission change for customer repo ([#109](https://github.com/tecton-ai/tecton-terraform-setup/issues/109)) ([4b9f574](https://github.com/tecton-ai/tecton-terraform-setup/commit/4b9f574f5fa8f34e823b2f4ddfe7fe93a5b074a0))
* add rift example and tweaks ([#123](https://github.com/tecton-ai/tecton-terraform-setup/issues/123)) ([8183d3c](https://github.com/tecton-ai/tecton-terraform-setup/commit/8183d3c003273262f222e2a697b593e3958fe384))
* add support for customer managed kms key ([#107](https://github.com/tecton-ai/tecton-terraform-setup/issues/107)) ([8a6dae7](https://github.com/tecton-ai/tecton-terraform-setup/commit/8a6dae73ec4d9a5deb3997872479fc153913ef9c))
* add validation script ([#103](https://github.com/tecton-ai/tecton-terraform-setup/issues/103)) ([62883dc](https://github.com/tecton-ai/tecton-terraform-setup/commit/62883dcbd2509303449134f945159d40848480b4))
* allow EMR roles to pull ECR images ([#110](https://github.com/tecton-ai/tecton-terraform-setup/issues/110)) ([2a2e1ee](https://github.com/tecton-ai/tecton-terraform-setup/commit/2a2e1ee0826ad5d0c4cc0d10009d698655771bc9))
* Enable EMR notebook cluster logs access when debugging enabled  ([#57](https://github.com/tecton-ai/tecton-terraform-setup/issues/57)) ([77318d9](https://github.com/tecton-ai/tecton-terraform-setup/commit/77318d9174d7aab78318da919f6ac2b85e802b26))
* fine-grained S3 permissions ([#179](https://github.com/tecton-ai/tecton-terraform-setup/issues/179)) ([950c7df](https://github.com/tecton-ai/tecton-terraform-setup/commit/950c7df2dfdefb0697cfa667303fe2c849a249ae))
* fully support KMS on rift ([35b3c6b](https://github.com/tecton-ai/tecton-terraform-setup/commit/35b3c6b6065ef847be2d33e25f6bb8e26ecd22aa))
* privatelink-cross-vpc module ([#100](https://github.com/tecton-ai/tecton-terraform-setup/issues/100)) ([a2ab6ff](https://github.com/tecton-ai/tecton-terraform-setup/commit/a2ab6ff14c69cc04d77e21296c317a472307b988))
* reduce down the permissions required by Rift VM ([#147](https://github.com/tecton-ai/tecton-terraform-setup/issues/147)) ([b0813af](https://github.com/tecton-ai/tecton-terraform-setup/commit/b0813afeb2c1a980ad986df59f3c0657c093203a))
* s3 bucket policy to allow cross-account read-write access ([#120](https://github.com/tecton-ai/tecton-terraform-setup/issues/120)) ([a5b2826](https://github.com/tecton-ai/tecton-terraform-setup/commit/a5b282654929147ee28414a6c1850eb33f78eee6))
* separate flags controlling spark and rift iam resources [DVOPS-1809] ([#144](https://github.com/tecton-ai/tecton-terraform-setup/issues/144)) ([087e327](https://github.com/tecton-ai/tecton-terraform-setup/commit/087e327036179c7d7c702db2d86b997c6f335cc7))
* set bucket acl to BucketOwnerEnforced ([#51](https://github.com/tecton-ai/tecton-terraform-setup/issues/51)) ([006a177](https://github.com/tecton-ai/tecton-terraform-setup/commit/006a177e7491b3bf560576046800eceb607471e8))
* support AssumeRole into cross-account intermediate role ([#152](https://github.com/tecton-ai/tecton-terraform-setup/issues/152)) ([c2856e8](https://github.com/tecton-ai/tecton-terraform-setup/commit/c2856e8e04cd8eec76c90731bccc20fad17825f4))
* support rift_compute module and rift on dataplane [DVOPS-1808] ([#141](https://github.com/tecton-ai/tecton-terraform-setup/issues/141)) ([e469449](https://github.com/tecton-ai/tecton-terraform-setup/commit/e4694495d4494f8fb33887d0821df9414873c485))
* tighter s3 controls + emr/notebook init args ([#97](https://github.com/tecton-ai/tecton-terraform-setup/issues/97)) ([1299d3b](https://github.com/tecton-ai/tecton-terraform-setup/commit/1299d3bd86d2fcf26685ae2393fb9a859c5218f7))


### Bug Fixes

* add missing local variable ([#130](https://github.com/tecton-ai/tecton-terraform-setup/issues/130)) ([10d7928](https://github.com/tecton-ai/tecton-terraform-setup/commit/10d7928b924dc11d8ead418f90b123db14f4da0b))
* Give EMR spark role access to notebook cluster logs s3 bucket ([#58](https://github.com/tecton-ai/tecton-terraform-setup/issues/58)) ([1598e50](https://github.com/tecton-ai/tecton-terraform-setup/commit/1598e50b2a4d4754e95ef2375ab08d2a581177a8))
* Remove ACL from the S3 bucket `tecton` ([#75](https://github.com/tecton-ai/tecton-terraform-setup/issues/75)) ([9fc8f31](https://github.com/tecton-ai/tecton-terraform-setup/commit/9fc8f31df82802519cc872a45280086d44b8928d))
* Remove warnings for S3 bucket server side encryption configuration & acl ([#74](https://github.com/tecton-ai/tecton-terraform-setup/issues/74)) ([71e12a0](https://github.com/tecton-ai/tecton-terraform-setup/commit/71e12a0b6a64ace605f88f9dbb9c671fd51bf500))
* typo ([#142](https://github.com/tecton-ai/tecton-terraform-setup/issues/142)) ([b8e094d](https://github.com/tecton-ai/tecton-terraform-setup/commit/b8e094d4b43890d332593aae5b034dfd4fb802d0))
* Update dynamo cross account role with new time to live roles ([#145](https://github.com/tecton-ai/tecton-terraform-setup/issues/145)) ([7ad35bc](https://github.com/tecton-ai/tecton-terraform-setup/commit/7ad35bcef2492d3c4fcaf618e8c6464dedf9943b))
