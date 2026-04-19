# Create a phone + tablet AVD using the Play-enabled API 35 x86_64 system
# image. Run once: powershell -ExecutionPolicy Bypass -File tool/create_avds.ps1
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$avdmanager = "$sdk\cmdline-tools\latest\bin\avdmanager.bat"
$package = "system-images;android-35;google_apis_playstore;x86_64"

# Phone: Pixel 6 is a representative modern portrait device.
& $avdmanager create avd --name "mtg_phone" --package $package --device "pixel_6" --force

# Tablet: "Medium Tablet" is Google's generic 7-8" tablet profile which
# produces screenshots Play Console accepts as "7-inch tablet".
& $avdmanager create avd --name "mtg_tablet" --package $package --device "medium_tablet" --force
