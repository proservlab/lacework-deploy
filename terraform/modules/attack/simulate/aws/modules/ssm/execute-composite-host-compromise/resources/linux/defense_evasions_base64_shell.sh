#!/bin/bash

$PAYLOAD=$(echo -en '#!/bin/bash\necho test\n' | base64)
echo -n $PAYLOAD | base64 -d /bin/bash