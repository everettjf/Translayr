#!/bin/sh


echo "Incrementing build number"
./scripts/increment-build.sh
echo "Incrementing version number"
./scripts/increment-version.sh


echo "Committing and pushing changes"
git add .
git commit -m "Increment build and version number"
git push


echo "Building release"
./scripts/build-release.sh


echo "✅Done"
echo "
 _    _                                 _              _             
| |  | |                               (_)            | |            
| |__| | __ ___   _____    __ _   _ __  _  ___ ___  | |_ __ _ _   _
|  __  |/ _\` \ \ / / _ \  / _\` | | '_ \| |/ __/ _ \ | __/ _\` | | | |
| |  | | (_| |\ V /  __/ | (_| | | | | | | (_|  __/ | || (_| | |_| |
|_|  |_|\__,_| \_/ \___|  \__,_| |_| |_|_|\___\___|  \__\__,_|\__, |
                                                                 __/ |
                                                                |___/ "
