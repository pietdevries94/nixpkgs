{
  stdenv,
  lib,
  bash,
  curl,
  fetchFromGitHub,
  gawk,
  installShellFiles,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "amazon-ec2-utils";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "amazonlinux";
    repo = "amazon-ec2-utils";
    tag = "v${version}";
    hash = "sha256-plTBh2LAXkYVSxN0IZJQuPr7QxD7+OAqHl/Zl8JPCmg=";
  };

  outputs = [
    "out"
    "man"
  ];

  strictDeps = true;

  nativeBuildInputs = [
    installShellFiles
  ];

  buildInputs = [
    bash
    python3
  ];

  postInstall = ''
    install -Dm755 -t $out/bin/ ebsnvme-id
    install -Dm755 -t $out/bin/ ec2-metadata
    install -Dm755 -t $out/bin/ ec2nvme-nsid
    install -Dm755 -t $out/bin/ ec2udev-vbd

    install -Dm644 -t $out/lib/udev/rules.d/ 51-ec2-hvm-devices.rules
    install -Dm644 -t $out/lib/udev/rules.d/ 51-ec2-xen-vbd-devices.rules
    install -Dm644 -t $out/lib/udev/rules.d/ 53-ec2-read-ahead-kb.rules
    install -Dm644 -t $out/lib/udev/rules.d/ 70-ec2-nvme-devices.rules
    install -Dm644 -t $out/lib/udev/rules.d/ 60-cdrom_id.rules

    installManPage doc/*.8
  '';

  postFixup = ''
    substituteInPlace $out/lib/udev/rules.d/{51-ec2-hvm-devices,70-ec2-nvme-devices}.rules \
      --replace-fail '/usr/sbin' "$out/bin"

    substituteInPlace $out/lib/udev/rules.d/53-ec2-read-ahead-kb.rules \
      --replace-fail '/bin/awk' '${gawk}/bin/awk'

    substituteInPlace "$out/bin/ec2-metadata" \
      --replace-fail 'curl' '${curl}/bin/curl'
  '';

  doInstallCheck = true;

  # We cannot run
  #     ec2-metadata --help
  # because it actually checks EC2 metadata even if --help is given
  # so it won't work in the test sandbox.
  installCheckPhase = ''
    $out/bin/ebsnvme-id --help
  '';

  meta = with lib; {
    changelog = "https://github.com/amazonlinux/amazon-ec2-utils/releases/tag/v${version}";
    description = "Contains a set of utilities and settings for Linux deployments in EC2";
    homepage = "https://github.com/amazonlinux/amazon-ec2-utils";
    license = licenses.mit;
    maintainers = with maintainers; [
      ketzacoatl
      thefloweringash
      anthonyroussel
    ];
  };
}
