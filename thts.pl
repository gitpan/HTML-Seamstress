{
 my $id = 'name';
 my $library_method = 'content_handler';
 my @args = 'bob';

 $tree->$id->$library_method(@args)
}

{
 my $id = 'data';
 my $library_method = 'content_handler';
 my @args = '5/11/69';

 $tree->$id->$library_method(@args)
}

------ no way

$tree->get_name->replace_content('terrence brannon');
$tree->get_date->replace_content('5/11/69');

$tree->name('terrence brannon');
$tree-date('5/11/69');


