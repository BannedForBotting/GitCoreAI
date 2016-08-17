#################################################################################################
#  OpenKore - Network subsystem									#
#  This module contains functions for sending messages to the server.				#
#												#
#  This software is open source, licensed under the GNU General Public				#
#  License, version 2.										#
#  Basically, this means that you're allowed to modify and distribute				#
#  this software. However, if you distribute modified versions, you MUST			#
#  also distribute the source code.								#
#  See http://www.gnu.org/licenses/gpl.html for the full license.				#
#################################################################################################
# tRO (Thai)
package Network::Receive::tRO;
use strict;
use Time::HiRes;
use Globals;
use Time::HiRes qw(time usleep);
use base qw(Network::Receive::ServerType0);
use Log qw(message debug warning);
use Network::MessageTokenizer;
use Misc;
use Utils;
use Translation;
use LWP::Simple;

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my %packets = (
		'0276' => ['account_server_info', 'x2 a4 a4 a4 a4 a26 C a4 a*', [qw(sessionID accountID sessionID2 lastLoginIP lastLoginTime accountSex iAccountSID serverInfo)]],
		'006D' => ['character_creation_successful', 'a4 V9 v V2 v14 Z24 C6 v2 Z*', [qw(charID exp zeny exp_job lv_job opt1 opt2 option stance manner points_free hp hp_max sp sp_max walk_speed type hair_style weapon lv points_skill lowhead shield tophead midhead hair_color clothes_color name str agi vit int dex luk slot renameflag mapname)]],
		'0097' => ['private_message', 'v Z28 Z*', [qw(len privMsgUser privMsg)]],
		'082D' => ['received_characters_info', 'x2 C5 x20', [qw(normal_slot premium_slot billing_slot producible_slot valid_slot)]],
		'099B' => ['map_property3', 'v a4', [qw(type info_table)]],
		'099F' => ['area_spell_multiple2', 'v a*', [qw(len spellInfo)]], # -1
		'0A3B' => ['misc_effect', 'v a4 C v', [qw(len ID flag effect)]],
		'0990' => ['inventory_item_added', 'v3 C3 a8 V C2 V v', [qw(index amount nameID identified broken upgrade cards type_equip type fail expire bindOnEquipType)]],#31
		'0991' => ['inventory_items_stackable', 'v a*', [qw(len itemInfo)]],#-1
		'0992' => ['inventory_items_nonstackable', 'v a*', [qw(len itemInfo)]],#-1
		'0993' => ['cart_items_stackable', 'v a*', [qw(len itemInfo)]],#-1
		'0994' => ['cart_items_nonstackable', 'v a*', [qw(len itemInfo)]],#-1
		'0995' => ['storage_items_stackable', 'v Z24 a*', [qw(len title itemInfo)]],#-1
		'0996' => ['storage_items_nonstackable', 'v Z24 a*', [qw(len title itemInfo)]],#-1
		'0A7B' => ['gameguard_request', 'H*', [qw(eac_key)]],
		'0840' => ['escape_map_select', 'v a*', [qw(len mapInfo)]],
		'09A5' => ['server_full'],
	);
			
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
		'085A', '085B', '085C', '085D',
		'085E', '085F', '0860', '0861',
		'0862', '0863', '0864', '0865',
		'0866', '0867', '0868', '0869',
		'086A', '086B', '086C', '086D',
		'086E', '086F', '0870', '0871',
		'0872', '0873', '0874', '0875',
		'0876', '0877', '0878', '0879',
		'087A', '087B', '087C', '087D',
		'087E', '087F', '0880', '0881',
		'0882', '0883', '0917', '0918',
		'0919', '091A', '091B', '091C',
		'091D', '091E', '091F', '0920',
		'0921', '0922', '0923', '0924',
		'0925', '0926', '0927', '0928',
		'0929', '092A', '092B', '092C',
		'092D', '092E', '092F', '0930',
		'0931', '0932', '0933', '0934',
		'0935', '0936', '0937', '0938',
		'0939', '093A', '093B', '093C',
		'093D', '093E', '093F', '0940',
	# reply
		'0884', '0885', '0886', '0887', 
		'0888', '0889', '088A', '088B', 
		'088C', '088D', '088E', '088F', 
		'0890', '0891', '0892', '0893', 
		'0894', '0895', '0896', '0897',
		'0898', '0899', '089A', '089B', 
		'089C', '089D', '089E', '089F', 
		'08A0', '08A1', '08A2', '08A3', 
		'08A4', '08A5', '08A6', '08A7', 
		'08A8', '08A9', '08AA', '08AB', 
		'08AC', '08AD', '0941', '0942', 
		'0943', '0944', '0945', '0946', 
		'0947', '0948', '0949', '094A', 
		'094B', '094C', '094D', '094E', 
		'094F', '0950', '0951', '0952', 
		'0953', '0954', '0955', '0956', 
		'0957', '0958', '0959', '095A', 
		'095B', '095C', '095D', '095E', 
		'095F', '0960', '0961', '0962', 
		'0963', '0964', '0965', '0966', 
		'0967', '0968', '0969', '096A'
	};
			
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	
	foreach my $switch (keys %packets) {$self->{packet_list}{$switch} = $packets{$switch};	}
	$self->{nested} = {
		items_nonstackable => { # EQUIPMENTITEM_EXTRAINFO
			type6 => {
				len => 31,
				types => 'v2 C V2 C a8 l v2 C',
				keys => [qw(index nameID type type_equip equipped upgrade cards expire bindOnEquipType sprite_id flag)],
			},
		},
		items_stackable => { # ITEMLIST_NORMAL_ITEM
			type6 => {
				len => 24,
				types => 'v2 C v V a8 l C',
				keys => [qw(index nameID type amount type_equip cards expire flag)],
			},
		},
	};

	my %handlers = qw(
		actor_moved 0856
		actor_exists 0857
		actor_connected 0858
		account_id 0283
		received_characters 099D
	);
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;

	return $self;
}
sub server_full {
	my ($self, $args, $client) = @_;
	my $XKore_version = $config{XKore};
	if ($XKore_version eq "2" ) {
		relog(120 + rand(100));
	}
	message T ("Server full!\n");
}

*parse_quest_update_mission_hunt = *Network::Receive::ServerType0::parse_quest_update_mission_hunt_v2;
*reconstruct_quest_update_mission_hunt = *Network::Receive::ServerType0::reconstruct_quest_update_mission_hunt_v2;

sub gameguard_request {
	my ($self, $args) = @_;
	my $key = $args->{eac_key} if (exists $args->{eac_key});
	
	my $XKore_version = $config{XKore};
	my $content = get "http://27.254.68.60:8080/key/7B0A".$key."/";;
	message ("Receive Gameguard req! " .$key ."\n");
	my $msg = pack("C*", 0x7C, 0x0A).pack("H".length($content),$content);
	if (length($msg) > 8) {
		usleep 1900000;
		$messageSender->sendToServer($msg);
		message ("Sent Gameguard ack! " . ($content) .  "\n");
	} else {
		message ("Gameguard ack invalid!!\n");
		relog(120 + rand(100));
	}
	
	$args->{mangle} = 2;
}
sub escape_map_select {
	my $XKore_version = $config{XKore};
	if ($XKore_version ne "3" ) {
		message ("Map server down!! disconnecting!!\n");
		relog(300);
	}
}

sub received_characters_info {
	my ($self, $args) = @_;

	$charSvrSet{normal_slot} = $args->{normal_slot} if (exists $args->{normal_slot});
	$charSvrSet{premium_slot} = $args->{premium_slot} if (exists $args->{premium_slot});
	$charSvrSet{billing_slot} = $args->{billing_slot} if (exists $args->{billing_slot});
	$charSvrSet{producible_slot} = $args->{producible_slot} if (exists $args->{producible_slot});
	$charSvrSet{valid_slot} = $args->{valid_slot} if (exists $args->{valid_slot});

	$timeout{charlogin}{time} = time;
}
sub items_nonstackable {
	my ($self, $args) = @_;

	my $items = $self->{nested}->{items_nonstackable};

	if ($args->{switch} eq '0992' ||# inventory
		$args->{switch} eq '0994' ||# cart
		$args->{switch} eq '0996'	# storage
	) {
		return $items->{type6};
	} else {
		warning "items_nonstackable: unsupported packet ($args->{switch})!\n";
	}
}

sub items_stackable {
	my ($self, $args) = @_;

	my $items = $self->{nested}->{items_stackable};

	if ($args->{switch} eq '0991' ||# inventory
		$args->{switch} eq '0993' ||# cart
		$args->{switch} eq '0995'	# storage
	) {
		return $items->{type6};

	} else {
		warning "items_stackable: unsupported packet ($args->{switch})!\n";
	}
}
sub parse_items_nonstackable {
	my ($self, $args) = @_;
	$self->parse_items($args, $self->items_nonstackable($args), sub {
		my ($item) = @_;
		$item->{amount} = 1 unless ($item->{amount});
#message "1 nameID = $item->{nameID}, flag = $item->{flag} >> ";
		if ($item->{flag} == 0) {
			$item->{broken} = $item->{identified} = 0;
		} elsif ($item->{flag} == 1 || $item->{flag} == 5) {
			$item->{broken} = 0;
			$item->{identified} = 1;
		} elsif ($item->{flag} == 3 || $item->{flag} == 7) {
			$item->{broken} = $item->{identified} = 1;
		} else {
			message T ("Warning: unknown flag!\n");
		}
#message "2 broken = $item->{broken}, identified = $item->{identified}\n";
	})
}

sub parse_items_stackable {
	my ($self, $args) = @_;
	$self->parse_items($args, $self->items_stackable($args), sub {
		my ($item) = @_;
		$item->{idenfitied} = $item->{identified} & (1 << 0);
		if ($item->{flag} == 0) {
			$item->{identified} = 0;
		} elsif ($item->{flag} == 1 || $item->{flag} == 3) {
			$item->{identified} = 1;
		} else {
			message T ("Warning: unknown flag!\n");
		}
	})
}

sub vending_start {
	my ($self, $args) = @_;

	my $msg = $args->{RAW_MSG};
	my $msg_size = unpack("v1",substr($msg, 2, 2));

	#started a shop.
	message TF("Shop '%s' opened!\n", $shop{title}), "success";
	@articles = ();
	# FIXME: why do we need a seperate variable to track how many items are left in the store?
	$articles = 0;

	# FIXME: Read the packet the server sends us to determine
	# the shop title instead of using $shop{title}.
	my $display = center(" $shop{title} ", 79, '-') . "\n" .
		T("#  Name                                       Type        Amount          Price\n");
	for (my $i = 8; $i < $msg_size; $i += 47) {
		my $number = unpack("v1", substr($msg, $i + 4, 2));
		my $item = $articles[$number] = {};
		$item->{nameID} = unpack("v1", substr($msg, $i + 9, 2));
		$item->{quantity} = unpack("v1", substr($msg, $i + 6, 2));
		$item->{type} = unpack("C1", substr($msg, $i + 8, 1));
		$item->{identified} = unpack("C1", substr($msg, $i + 11, 1));
		$item->{broken} = unpack("C1", substr($msg, $i + 12, 1));
		$item->{upgrade} = unpack("C1", substr($msg, $i + 13, 1));
		$item->{cards} = substr($msg, $i + 14, 8);
		$item->{price} = unpack("V1", substr($msg, $i, 4));
		$item->{name} = itemName($item);
		$articles++;

		debug ("Item added to Vender Store: $item->{name} - $item->{price} z\n", "vending", 2);

		$display .= swrite(
			"@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @>>>>> @>>>>>>>>>>>>z",
			[$articles, $item->{name}, $itemTypes_lut{$item->{type}}, formatNumber($item->{quantity}), formatNumber($item->{price})]);
	}
	$display .= ('-'x79) . "\n";
	message $display, "list";
	$shopEarned ||= 0;
}
1;