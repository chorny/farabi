package Farabi;

use Mojo::Base 'Mojolicious';
use Path::Tiny;

# ABSTRACT: Modern Perl IDE
# VERSION

# Application SQLite database and projects are stored in this directory
has 'home_dir';

# Projects are stored in this directory
has 'projects_dir';

# The database name and location
has 'db_name';

sub startup {
	my $app = shift;

	# Change secret passphrase that is used for signed cookies
	$app->secrets(['Hulk, Smash!']);

	# Use content from directories under lib/Farabi/files
	$app->home->parse( path( path(__FILE__)->dirname, 'Farabi' ) );
	$app->static->paths->[0]   = $app->home->rel_dir('files/public');
	$app->renderer->paths->[0] = $app->home->rel_dir('files/templates');

	# Define routes
	my $route = $app->routes;
	$route->get('/')->to('editor#default');

	eval { $app->_setup_dirs };
	if ($@) {
		die "Failure to create \$HOME/.farabi directory structure, reason: $@";
	}

	# The database name
	$app->db_name(path($app->home_dir, 'farabi.db'));

	# Setup the Farabi database
	eval { $app->_setup_database };
	if ($@) {
		warn "Database not setup, reason: $@";
	}

	# Setup websocket message handler
	$route->websocket('/websocket')->to('editor#websocket');
}

#
# Create the following directory structure:
# .farabi
# .farabi/projects
#
sub _setup_dirs {
	my $app = shift;

	require File::HomeDir;

	$app->home_dir( path( File::HomeDir->home, ".farabi" ) );
	$app->projects_dir( path( $app->home_dir, "projects" ) );
	$app->projects_dir->mkpath;
}

# Setup the Farabi database
sub _setup_database {
	my $app = shift;

	# Connect and create the Farabi SQLite database if not found
	require DBIx::Simple;
	my $db_name = $app->db_name;
	my $db = DBIx::Simple->connect("dbi:SQLite:dbname=$db_name");

	# Create tables if they do not exist
	$db->query(<<SQL);
CREATE TABLE IF NOT EXISTS recent_list (
	id        INTEGER PRIMARY KEY AUTOINCREMENT, 
	name      TEXT,
	type      TEXT,
	last_used TEXT
)
SQL

	# Disconnect from database
	$db->disconnect;
}

1;
__END__

=pod

=head1 SYNOPSIS

  # Run on the default port 4040
  $ farabi
  
  # Run it on port 5050
  $ farabi --port 5050

=head1 DESCRIPTION

This is a modern web-based Perl IDE that runs inside your favorite browser.

Please run the following command and then open http://127.0.0.1:4040 in your browser:

  farabi


=head1 FEATURES

=over

=item Open File(s)

The dialog provides partial filename search inside the directory where Farabi was started.
Matched single or multiple file selections can then be opened in one batch.

B<WARNING:> Please do not start farabi in a folder with too many files like your home directory
because this feature's performance will eventually suffer.

=back

=head1 TECHNOLOGIES USED

=over

=item *

L<Mojolicious|http://mojolicio.us> - A next generation web framework for the Perl programming language

=item *

L<jQuery|http://jquery.com/> - A new kind of JavaScript Library

=item *

L<JSHint|http://jshint.com/> - A JavaScript Code Quality Tool

=item *

L<Bootstrap|http://twitter.github.com/bootstrap> - Sleek, intuitive, and powerful front-end framework for faster and easier web development

=item *

L<CodeMirror|http://codemirror.net> - In-browser code editing made bearable

=item *

L<Perlito|http://perlito.org/> - Runtime for "Perlito" Perl5-in-Javascript

=back

=head1 SEE ALSO

L<EPIC|http://www.epic-ide.org/>, L<Kephra>, L<Padre>, L<TryPerl|http://tryperl.com/>

=head1 HISTORY

The idea started back in March 2012 as a fork of L<Padre>. I wanted to dump L<Wx> for the browser. 
The first version was in 11th April as L<Mojolicious::Plugin::Pedro>. It used the ACE Javascript
editor and jQuery UI. Then i hibernated for a while to play games :) Later I heard about L<Galileo>.
It basically used the same idea, mojolicious backend, browser for the frontend. So I stopped 
playing games and rolled my sleeves to focus on Pedro.

Later I discovered Pedro was not a good name for my project. So I chose Farabi for
L<Al-Farabi|http://en.wikipedia.org/wiki/Al-Farabi> who was a renowned scientist and philosopher
of the Islamic Golden Age. He was also a cosmologist, logician,and musician.

=head1 SUPPORT

If you find a bug, please report it in:

L<https://github.com/azawawi/farabi/issues>

If you find this module useful, please rate it in:

L<http://cpanratings.perl.org/d/Farabi>

=head1 AUTHORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 CONTRIBUTORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=cut
