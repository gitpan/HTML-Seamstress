use lib '.';
use html::hello_world;

print html::hello_world
  ->name('joejoe')
  ->date(`date`)
  ->as_HTML;
