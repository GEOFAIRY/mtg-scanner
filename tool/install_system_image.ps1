# One-off: install the Play-enabled Android 35 x86_64 system image so
# we can create phone + tablet AVDs for Play Store screenshots.
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" "system-images;android-35;google_apis_playstore;x86_64"
