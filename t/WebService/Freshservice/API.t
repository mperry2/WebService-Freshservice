#!/usr/bin/perl -w

use lib 't/lib/';

use WebService::Freshservice::Test;
use Test::Most;
use Test::Warnings;

my $tester = WebService::Freshservice::Test->new();

$tester->test_with_dancer(\&user_testing, 7);

sub user_testing {
  my ($api,$message) = @_;

  pass("User Testing: $message");  
  use_ok("WebService::Freshservice::User");
  

  subtest 'Instantiation' => sub {
    isa_ok($api, "WebService::Freshservice::API");
    can_ok($api, qw( get_api post_api ) );
  };
  
  subtest 'Get Method' => sub {
    my $get = $api->get_api( "/itil/requesters/1234.json" );
    is( $get->{user}{name}, "Test", "'get_api' returns data" );
    dies_ok { $api->get_api("invalid") } "'get_api' dies when JSON not received";
  };
   
  subtest 'Post Method' => sub {
    my $user->{user}{name} = "Test";
    my $post = $api->post_api( "/itil/requesters.json", $user );
    is( $post->{user}{name}, "Test", "'get_api' returns data" );
    dies_ok { $api->post_api("invalid") } "'get_api' dies when JSON not received";
  };
   
  subtest 'Failures' => sub {
    dies_ok { $api->_build__ua('argurment') } "method '_build__ua' doesn't accept arguments";
    dies_ok { $api->get_api() } "method 'get_api' requires an argument";
    dies_ok { $api->get_api('arg1', 'arg2' ) } "method 'get_api' only takes a singular argument";
    dies_ok { $api->post_api() } "method 'post_api' requires arguments";
    dies_ok { $api->post_api('arg1', 'arg2', 'arg3') } "method 'post_api' only takes 2 arguments";
  };
}

done_testing();
__END__