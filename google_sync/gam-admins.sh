function gam() { "$HOME/bin/gam/gam" "$@" ; }

export FILEPATH=$(realpath $0)
export PROJECT_DIR=$(dirname $FILEPATH)

export GAM_THREADS=$GAM_THREADS

mkdir -p $PROJECT_DIR/data
mkdir -p $PROJECT_DIR/log

printf "Extracting user files from database...\n"
cd $DATAGUN_DIR
pdm run extract --config ./datagun/config/gapps-admins.json
printf "\n"

cd $PROJECT_DIR

printf "Exporting existing admins from Google to $GAM_ADMINS_EXPORT_FILE\n"
gam print admins role "Reset Student PW" > $GAM_ADMINS_EXPORT_FILE
printf "\n"

printf "Transforming final sync file\n"
pdm run prep-users
printf "\n"

for dir in $PROJECT_DIR/data/*/;
do
    dir=${dir%*/}
    region=${dir##*/}

    mkdir -p $PROJECT_DIR/data/$region
    mkdir -p $PROJECT_DIR/log/$region

    printf "$region - Creating Reset Student PW admins...\n"
    admin_file=$dir/admin_create.csv
    if [ -f $admin_file ]; then
        filename=$(basename -- "$admin_file")
        filename="${filename%.*}"

        gam csv $admin_file \
        gam create \
            admin ~user \
            "Reset Student PW" \
            org_unit ~OU

        rm $admin_file
    else
        printf "\tNo admins to create!\n"
    fi
    printf "\n"
done
