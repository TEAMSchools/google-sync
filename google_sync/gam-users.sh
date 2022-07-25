function gam() { "$HOME/bin/gam/gam" "$@" ; }

export FILEPATH=$(realpath $0)
export PROJECT_DIR=$(dirname $FILEPATH)

export GAM_THREADS=$GAM_THREADS

mkdir -p $PROJECT_DIR/data/users
mkdir -p $PROJECT_DIR/log/users

cd $PROJECT_DIR

printf "Exporting existing users from Google to $GAM_USERS_EXPORT_FILE\n"
gam print users domain $GOOGLE_STUDENTS_DOMAIN firstname lastname ou suspended \
    > $GAM_USERS_EXPORT_FILE
printf "\n"

printf "Transforming final sync file\n"
pdm run prep-admins
printf "\n"

for dir in $PROJECT_DIR/data/users/*/;
do
    dir=${dir%*/}
    region=${dir##*/}

    mkdir -p $PROJECT_DIR/data/users/$region
    mkdir -p $PROJECT_DIR/log/users/$region

    printf "$region - Creating users...\n"
    create_file=$dir/user_create.csv
    if [ -f $create_file ]; then
        printf "$create_file\n"

        filename=$(basename -- "$create_file")
        filename="${filename%.*}"

        gam csv $create_file \
        gam create \
            user ~email \
            firstname ~firstname \
            lastname ~lastname \
            suspended ~suspended_x \
            org ~org \
            password ~password \
            changepassword ~changepassword

        rm $create_file
    else
        printf "\tNo users to create!\n"
    fi
    printf "\n"

    printf "$region - Updating users w/ pw...\n"
    update_pw_file=$dir/user_update_pw.csv
    if [ -f $update_pw_file ]; then
        printf "$update_pw_file\n"

        filename=$(basename -- "$update_pw_file")
        filename="${filename%.*}"

        gam csv $update_pw_file \
        gam update \
            user ~primaryEmail \
            firstname ~firstname \
            lastname ~lastname \
            suspended ~suspended_x \
            org ~org \
            password ~password

        rm $update_pw_file
    else
        printf "\tNo users to update w/ pw!\n"
    fi
    printf "\n"

    printf "$region - Updating users w/o pw...\n"
    update_nopw_file=$dir/user_update_nopw.csv
    if [ -f $update_nopw_file ]; then
        printf "$update_nopw_file\n"

        filename=$(basename -- "$update_nopw_file")
        filename="${filename%.*}"

        gam csv $update_nopw_file \
        gam update \
            user ~primaryEmail \
            firstname ~firstname \
            lastname ~lastname \
            suspended ~suspended_x \
            org ~org

        rm $update_nopw_file
    else
        printf "\tNo users to update w/o pw!\n"
    fi
    printf "\n"

    printf "$region - Syncing user group membership...\n"
    group_file=$dir/group.csv
    if [ -f $group_file ]; then
        filename=$(basename -- "$group_file")
        filename="${filename%.*}"

        gam csv $group_file \
        gam update \
            group ~group_email \
            sync member notsuspended nomail \
            ou_and_children "/Students/~~region~~"
    fi
    printf "\n"
done
