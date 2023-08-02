<p align="center">
  <img src="https://github.com/macaroni-os/macaroni-site/blob/master/site/static/images/logo.png">
</p>

# macaroni-security

Macaroni OS Security Repository where release packages with a fast
rolling release and with security patches.

At the moment it's used only for Phoenix release.

## luet-portage-converter

In this repository we avoid to generate all dependencies, for
this reason with use the option `--layer4rdepends` in this way for example:

```bash
$> luet-portage-converter generate \
    --rules portage-converter/browsers-extra.yaml \
    --ignore-missing-deps   --disable-conflicts \
    --to . --enable-stage4 --ignore-wrong-packages \
    -t packages/  --layer4rdepends
```
