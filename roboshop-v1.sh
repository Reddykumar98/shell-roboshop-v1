#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="daws92k.store"
hosted_zone_id="Z0908977HOWAYRSVDR61"

for instance in $@
do
   echo "Creating instance: $instance"
done