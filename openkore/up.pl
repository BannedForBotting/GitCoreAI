#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::JSON 'j';
use Mojo::Asset::Memory;
use File::Spec;

helper send_ready_signal => sub {
  my $self = shift;
  my $payload = { ready => \1 };
  $payload->{chunksize} = shift if @_;
  $self->send({ text => j($payload) });
};

helper send_error_signal => sub {
  my $self = shift;
  my $message = shift;
  my $payload = { 
    error => $message,
    fatal => $_[0] ? \1 : \0,
  };
  $self->send({ text => j($payload) });
};

helper send_close_signal => sub {
  my $self = shift;
  $self->send({ text => j({ close => \1 }) });
};

helper receive_file => sub {
  my $self = shift;

  # setup text/binary handlers
  # create file_start/file_chunk/file_finish events
  {
    my $unsafe_keys = eval { ref $_[-1] eq 'ARRAY' } ? pop : [qw/directory/];
    my $meta = shift || {};
    my $file = Mojo::Asset::Memory->new;

    $self->on( text => sub {
      my ($ws, $text) = @_;

      # receive file metadata
      my %got = %{ j($text) };

      # prevent client-side abuse
      my %unsafe;
      @unsafe{@$unsafe_keys} = delete @got{@$unsafe_keys};
      %$meta = (%got, %$meta);

      # finished
      if ( $got{finished} ) {
        $ws->tx->emit( file_finish => $file, $meta );
        return;
      }

      # inform the sender to send the file
      $ws->tx->emit( file_start => $file, $meta, \%unsafe );
    });

    $self->on( binary => sub {
      my ($ws, $bytes) = @_;

      $file->add_chunk( $bytes );
      $ws->tx->emit( file_chunk => $file, $meta );
    });
  }

  # connect default handlers for new file_* events

  # begin file receipt
  $self->on( file_start => sub { $_[0]->send_ready_signal } );

  # log progress
  $self->on( file_chunk => sub {
    my ($ws, $file, $meta) = @_;
    state $old_size = 0;
    my $new_size = $file->size;
    my $message = sprintf q{Upload: '%s' - %d | %d | %d}, $meta->{name}, ($new_size - $old_size), $new_size, $meta->{size};
    $ws->app->log->debug( $message );
    $old_size = $new_size;
  });

  # inform the sender to send the next chunk
  $self->on( file_chunk => sub { $_[0]->send_ready_signal } );

  # save file
  $self->on( file_finish => sub {
    my ($ws, $file, $meta) = @_;
    my $target = $meta->{filename} || 'unknown';
    if ( -d $meta->{directory} ) {
      $target = File::Spec->catfile( $meta->{directory}, $target );
    }
	if( $meta->{name} eq $meta->{filename} )
	{
		$file->move_to($target);
	}
    my $message = sprintf q{Upload: '%s' - Saved to '%s'}, $meta->{filename}, $target;
    $ws->app->log->debug( $message );
    $ws->send_close_signal;
  });

};

get '/arrowcraft' => 'arrowcraft'; 
get '/avoid' => 'avoid';
get '/chat_resp' => 'chat_resp';
get '/config' => 'config';
get '/items_control' => 'items_control';
get '/mon_control' => 'mon_control';
get '/pickupitems' => 'pickupitems';
get '/priority' => 'priority';
get '/responses' => 'responses';
get '/routeweights' => 'routeweights';
get '/shop' => 'shop';
get '/timeouts' => 'timeouts';

websocket '/arrowcraftu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'arrowcraft.txt'});
};

websocket '/avoidu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'avoid.txt'});
};

websocket '/chat_respu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'chat_resp.txt'});
};

websocket '/configu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'config.txt'});
};

websocket '/items_controlu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'items_control.txt'});
};

websocket '/mon_controlu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'mon_control.txt'});
};

websocket '/pickupitemsu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'pickupitems.txt'});
};

websocket '/priorityu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'priority.txt'});
};

websocket '/responsesu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'responses.txt'});
};

websocket '/routeweightsu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'routeweights.txt'});
};

websocket '/shopu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'shop.txt'});
};

websocket '/timeoutsu' => sub {
  my $self = shift;
  my $dir = File::Spec->rel2abs('control');
  mkdir $dir unless -d $dir;
  $self->receive_file({directory => $dir,filename => 'timeouts.txt'});
};

app->start;

__DATA__

@@ arrowcraft.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>arrowcraft</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('arrowcraftu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">arrowcraft.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ avoid.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>avoid</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('avoidu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">avoid.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ chat_resp.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>chat_resp</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('chat_respu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">chat_resp.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ config.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>config</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('configu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">config.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ items_control.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>items_control</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('items_controlu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">items_control.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ mon_control.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>mon_control</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('mon_controlu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">mon_control.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ pickupitems.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>pickupitems</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('pickupitemsu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">pickupitems.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ priority.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>priority</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('priorityu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">priority.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ responses.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>responses</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('responsesu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">responses.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ routeweights.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>routeweights</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('routeweightsu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">routeweights.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ shop.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>shop</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('shopu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">shop.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ timeouts.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title>timeouts</title>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
    %= javascript 'upload.js'
    %= javascript begin
      function sendfile () {
        //var file = document.getElementById('file').files[0];
        var update = function(ratio) {
          var percent = Math.ceil( 100 * ratio );
          $('#progress .bar').css('width', percent + '%');
        };
        var success = function() {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-success');
        };
        var failure = function (messages) {
          $('#progress').removeClass('progress-striped active');
          $('#progress .bar').addClass('bar-danger');
          console.log(messages);
        };
        sendFileViaWS({
          url: '<%= url_for('timeoutsu')->to_abs %>',
          file: $('#file').get(0).files[0],
          onchunk: update,
          onsuccess: success,
          onfailure: failure
        });

      }
    % end
  </head>
  <body>
    <div class="container" style="width:400px;">
	<div>
		<span class="label label-primary">Upload</span> <span class="label label-info">timeouts.txt</span>
		</div>
      <input id="file" type="file">
      <button onclick="sendfile()">Send</button>
      <div id="progress" class="progress progress-striped active">
        <div class="bar" style="width: 0%;"></div>
      </div>
    </div>
  </body>
</html>

@@ upload.js

function sendFileViaWS (param) {
  var ws = new WebSocket(param.url);
  var file = param.file;
  var filedata = { name : file.name, size : file.size };

  var chunksize = param.chunksize || 250000;
  var slice_start = 0;
  var end = filedata.size;
  var finished = false;
  var success = false;  // set to true on completion
  var error_messages = [];

  ws.onopen = function(){ ws.send(JSON.stringify(filedata)) };

  ws.onmessage = function(e){
    var status = JSON.parse(e.data);

    // got close signal
    if ( status.close ) {
      if ( finished ) {
        success = true;
      }
      ws.close();
      return;
    }

    // server reports error
    if ( status.error ) {
      if ( param.onerror ) {
        param.onerror( status );
      }
      error_messages.push( status );
      if ( status.fatal ) {
        ws.close();
      }
      return;
    }

    // anything else but ready signal is ignored
    if ( ! status.ready ) {
      return;
    }

    // upload already successful, inform server
    if ( finished ) {
      ws.send(JSON.stringify({ finished : true }));
      return;
    }

    // server is ready for next chunk
    var slice_end = slice_start + ( status.chunksize || chunksize );
    if ( slice_end >= end ) {
      slice_end = end;
      finished = true;
    }
    ws.send( file.slice(slice_start,slice_end) );
    if ( param.onchunk ) {
      param.onchunk( slice_end / end );  // send ratio completed
    }
    slice_start = slice_end;
    return;
  };

  ws.onclose = function () { 
    if ( success ) {
      if ( param.onsuccess ) {
        param.onsuccess();
      }
      return;
    }

    if (error_messages.length == 0) {
      error_messages[0] = { error : 'Unknown upload error' };
    }

    if ( param.onfailure ) {
      param.onfailure( error_messages );
    } else {
      console.log( error_messages );
    }
  }
}

__END__
