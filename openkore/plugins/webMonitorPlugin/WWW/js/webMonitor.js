(function($) {
	$(function() {
		var messageHTML = function(html, domain) {
			$('.log').each(function() {
				var domains = $(this).data('domains')
				if (domains && $.inArray(domain, domains.split(' ')) == -1) return;

				$(this).stop()
				// autoscroll only if already are at bottom
				var scrolled = $(this).scrollTop() > $(this).prop('scrollHeight') - $(this).prop('offsetHeight') * 1.5

				$(this).append(html)

				if (scrolled) {
					$(this).animate({scrollTop: $(this).prop('scrollHeight')}, 'fast')
				}
			})
		}

		var message = function(text, domain, cssClass) {
			var line = $('<span/>')
			line.addClass(cssClass)
			line.text(text)
			messageHTML(line, domain)
		}

		// initial log scrolling
		$('.log').each(function() {
			$(this).scrollTop($(this).prop('scrollHeight'))
		})

		$('abbr, [rel=tooltip]').tooltip()

		$('.map').each(function() {
			var c = $(this)[0].getContext('2d')
			c.fillStyle = '#ff0000'
			c.fillRect(150, 150, 5, 3)
		})
		

		var ctx = null ; 
		var map_width = 0;
		var map_height = 0;
		var map_lpx = 0;
		var map_lpy = 0;
		var mx = 0;
		var my = 0;
		function drawpos()
		{
			if( ctx == null )
			{
				var c = document.getElementById("map");
				if (c == null) 
				{
					return;
				}
				ctx = c.getContext("2d");
				if (ctx == null) 
				{
					return;
				}
				if( map_height != 0 && map_width != 0)
				{
					ctx.canvas.height = map_height;
					ctx.canvas.width = map_width;
				}
				ctx.save();


				c.addEventListener('click', function(event) {
					
					var rect = this.getBoundingClientRect();
					mx = event.clientX - rect.left;
					my = event.clientY - rect.top;
					
					var csrf = parseInt($('.csrf').text());
					if( mx > 0 && my > 0 && mx < ctx.canvas.height && my < ctx.canvas.width )
					{
						window.location.href = '../handler?csrf=' + csrf + '&command=move ' + Math.floor(my) + ' ' + Math.floor(mx);
					}

				}, false);
				
				c.addEventListener('mousemove', function(event) {
					var rect = this.getBoundingClientRect();
					mx = event.clientX - rect.left;
					my = event.clientY - rect.top;
				
				}, false);
			}

			ctx.setTransform(1, 0, 0, 1, 0, 0);
			ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
			ctx.restore();
			ctx.beginPath();
			ctx.arc(map_lpx, ctx.canvas.width - map_lpy, 2, 0, 2 * Math.PI);
			ctx.fillStyle = 'white';
			ctx.fill();
			ctx.lineWidth = 2;
			ctx.strokeStyle = '#FF0000';
			ctx.stroke();
		}
		map_lpx = parseInt($('.value_char_pos_x').text());
		map_lpy = parseInt($('.value_char_pos_y').text());
		drawpos();

		var socketAddr, socket;
		if (typeof WebSocket !== 'undefined' && CONFIG.socketPort) {
			socketAddr = CONFIG.socketHost + ':' + CONFIG.socketPort
			message("Connecting (" + socketAddr + ")... ", 'web', 'msg_web')

			socket = new WebSocket('ws://' + socketAddr + '/');

			socket.onopen = function() {
				console.log('Socket opened.');
				message("connected\n", 'web', 'msg_web')
				
				$("#button_send").removeAttr("disabled");
			}

			socket.onclose = function() {
				console.log('Socket closed.');
				message("Disconnecting (" + socketAddr + ")... disconnected\n", 'web', 'msg_web')
				message("Reload to get new messages.\n", 'web', 'msg_web')
				
				$("#button_send").attr("disabled", "disabled");
			}

			socket.onerror = function(e) {
				console.log('Socket error.', e);
				messageHTML('<br/>', 'web');
			}

			socket.onmessage = function(event) {
				packet = JSON.parse(event.data);

				switch (packet.type) {
					case 'console':
						message(packet.data.message, packet.data.domain, packet.data.class)
					break;
					case 'values':
						$.each(packet.data, function(key, value) {
							$('.value_' + key).text(value);
							var $progress = $('.progress_' + key);
							if ($progress.length) {
								var percent = (value * 100 / $('.value_' + key + '_max').first().text()).toFixed(2) + '%';
								$progress.attr({'data-original-title': percent});
								$progress.find('.bar').css({width: percent});
							}

							switch (key) {
								case 'field_image':
								{
									$('#map').css({'background-image': 'url("' + value + '")'});	
									ctx = null;
									break;
								}
								case 'field_width':
								{
									$('#map').css({'width': value + 'px'});
									map_width = value;
									break;
								}
								case 'field_height':
								{
									$('#map').css({'height': value + 'px'});
									map_height = value;
									break;
								}
								case 'char_pos_x':
								{
									map_lpx = value;
									drawpos();
									break;
								}
								case 'char_pos_y':
								{
									map_lpy = value;
									drawpos();
									break;
								}
							}
						});
					break;
					default:
						//console.log('Unknown message', message);
				}
			}
		} else {
			message("Reload to get new messages.\n", 'web', 'msg_web')
		}
	});
})(jQuery);
