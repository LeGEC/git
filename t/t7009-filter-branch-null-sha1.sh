#!/bin/sh

test_description='filter-branch removal of trees with null sha1'
. ./test-lib.sh

test_expect_success 'create base commits' '
	test_commit one &&
	test_commit two &&
	test_commit three
'

test_expect_success 'create a commit with a bogus null sha1 in the tree' '
	{
		git ls-tree HEAD &&
		printf "160000 commit $_z40\\tbroken\\n"
	} >broken-tree
	echo "add broken entry" >msg &&

	tree=$(git mktree <broken-tree) &&
	test_tick &&
	commit=$(git commit-tree $tree -p HEAD <msg) &&
	git update-ref HEAD "$commit"
'

# we have to make one more commit on top removing the broken
# entry, since otherwise our index does not match HEAD (and filter-branch will
# complain). We could make the index match HEAD, but doing so would involve
# writing a null sha1 into the index.
test_expect_success 'create a commit dropping the broken entry' '
	test_tick &&
	git commit -a -m "back to normal"
'

test_expect_success 'filter commands are still checked' '
	test_must_fail git filter-branch \
		--force --prune-empty \
		--index-filter "git rm --cached --ignore-unmatch three.t"
'

test_expect_success 'removing the broken entry works' '
	git filter-branch \
		--force --prune-empty \
		--index-filter "git rm --cached --ignore-unmatch broken"
'

test_expect_success 'resulting history is clean' '
	echo three >expect &&
	git log -1 --format=%s >actual &&
	test_cmp expect actual
'

test_done
