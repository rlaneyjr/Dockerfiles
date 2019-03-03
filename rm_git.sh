#!/usr/bin/env bash

cur_dir=$PWD
git_folders=`find $cur_dir -depth 2 -type d -name '.git*'`
git_file=`find $cur_dir -depth 2 -type f -name '.git*'`
git_lic=`find $cur_dir -depth 2 -type f -name LICENSE*`
git_con=`find $cur_dir -depth 2 -type f -name CONTRIBUTING*`
git_main=`find $cur_dir -depth 2 -type f -name MAINTAINERS*`
git_sec=`find $cur_dir -depth 2 -type f -name SECURITY*`
git_rel=`find $cur_dir -depth 2 -type f -name RELEASE*`

remove_file () {
    for f in $1; do
        echo "Removing $f";
        rm $f;
    done
}

update_remove_repo () {
    for f in $1; do
        repo=`echo $f | sed -e 's:/\.git.*\?$::'`;
        echo "Updating $repo";
        cd $repo && git pull && cd $cur_dir;
        echo "Removing $f";
        rm -rf $f;
    done
}

remove_file $git_file
remove_file $git_lic
remove_file $git_con
remove_file $git_main
remove_file $git_sec
remove_file $git_rel

update_remove_repo $git_folders

exit 0 
