-- Copyright 2018 Nick Peng (pymumu@gmail.com)

require ("nixio.fs")
require ("luci.http")
require ("luci.dispatcher")
require ("nixio.fs")

m = Map("smartdns")
m.title	= translate("SmartDNS Server")
m.description = translate("SmartDNS is a local high-performance DNS server, supports finding fastest IP, supports ad filtering, and supports avoiding DNS poisoning.")

m:section(SimpleSection).template  = "smartdns/smartdns_status"

-- Basic
s = m:section(TypedSection, "smartdns", translate("Settings"), translate("General Settings"))
s.anonymous = true

s:tab("settings", translate("General Settings"))
s:tab("custom", translate("Custom Settings"))

---- Eanble
o = s:taboption("settings", Flag, "enabled", translate("Enable"), translate("Enable or disable smartdns server"))
o.default     = o.disabled
o.rempty      = false

---- server name
o = s:taboption("settings", Value, "server_name", translate("Server Name"), translate("Smartdns server name"))
o.default     = "smartdns"
o.datatype    = "hostname"
o.rempty      = false

---- Port
o = s:taboption("settings", Value, "port", translate("Local Port"), translate("Smartdns local server port"))
o.placeholder = 6053
o.default     = 6053
o.datatype    = "port"
o.rempty      = false

---- Enable TCP server
o = s:taboption("settings", Flag, "tcp_server", translate("TCP Server"), translate("Enable TCP DNS Server"))
o.rmempty     = false
o.default     = o.enabled
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "1"
end

---- Support IPV6
o = s:taboption("settings", Flag, "ipv6_server", translate("IPV6 Server"), translate("Enable IPV6 DNS Server"))
o.rmempty     = false
o.default     = o.enabled
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "1"
end

---- Redirect
o = s:taboption("settings", ListValue, "redirect", translate("Redirect"), translate("SmartDNS redirect mode"))
o.placeholder = "none"
o:value("none", translate("none"))
o:value("dnsmasq-upstream", translate("Run as dnsmasq upstream server"))
o:value("redirect", translate("Redirect 53 port to SmartDNS"))
o.default     = "none"
o.rempty      = false

---- cache-size
o = s:taboption("settings", Value, "cache_size", translate("Cache Size"), translate("DNS domain result cache size"))
o.rempty      = true

---- rr-ttl
o = s:taboption("settings", Value, "rr_ttl", translate("Domain TTL"), translate("TTL for all domain result."))
o.rempty      = true

---- rr-ttl-min
o = s:taboption("settings", Value, "rr_ttl_min", translate("Domain TTL Min"), translate("Minimum TTL for all domain result."))
o.rempty      = true

---- rr-ttl-max
o = s:taboption("settings", Value, "rr_ttl_max", translate("Domain TTL Max"), translate("Maximum TTL for all domain result."))
o.rempty      = true


----- custom settings
custom = s:taboption("custom", Value, "Custom Settings",
	translate(""), 
	translate("smartdns custom settings"))

custom.template = "cbi/tvalue"
custom.rows = 20

function custom.cfgvalue(self, section)
	return nixio.fs.readfile("/etc/smartdns/custom.conf")
end

function custom.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("/etc/smartdns/custom.conf", value)
end

-- Upstream servers
s = m:section(TypedSection, "server", translate("Upstream Servers"), translate("Upstream Servers, support UDP, TCP protocol. " ..
	"Please configure multiple DNS servers, including multiple foreign DNS servers."))
	
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

---- name
s:option(Value, "name", translate("Name"), translate("DNS Server name"))
---- IP address
o = s:option(Value, "ip", translate("ip"), translate("DNS Server ip"))
o.datatype = "ipaddr"
o.rmempty = false 
---- port
o = s:option(Value, "port", translate("port"), translate("DNS Server port"))
o.placeholder = 53
o.default     = 53
o.datatype    = "port"
o.rempty      = false
---- type
o = s:option(ListValue, "type", translate("type"), translate("DNS Server type"))
o.placeholder = "udp"
o:value("udp", translate("udp"))
o:value("tcp", translate("tcp"))
o:value("tls", translate("tls"))
o.default     = "udp"
o.rempty      = false

---- blacklist_ip
o = s:option(Flag, "blacklist_ip", translate("IP Blacklist Filtering"), translate("Filtering IP with blacklist"))
o.rmempty     = false
o.default     = o.disabled
o.cfgvalue    = function(...)
    return Flag.cfgvalue(...) or "0"
end

-- Doman addresss
s = m:section(TypedSection, "smartdns", translate("Domain Address"), 
	translate("Set Specific domain ip address."))
s.anonymous = true

---- address
addr = s:option(Value, "address",
	translate(""), 
	translate("Specify an IP address to return for any host in the given domains, Queries in the domains are never forwarded and always replied to with the specified IP address which may be IPv4 or IPv6."))

addr.template = "cbi/tvalue"
addr.rows = 20

function addr.cfgvalue(self, section)
	return nixio.fs.readfile("/var/etc/smartdns/address.conf")
end

function addr.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("/var/etc/smartdns/address.conf", value)
end

-- IP Blacklist
s = m:section(TypedSection, "smartdns", translate("IP Blacklist"), 
	translate("Set Specific ip blacklist."))
s.anonymous = true

---- blacklist
addr = s:option(Value, "blacklist_ip",
	translate(""), 
	translate("Configure IP blacklists that will be filtered from the results of specific DNS server."))

addr.template = "cbi/tvalue"
addr.rows = 20

function addr.cfgvalue(self, section)
	return nixio.fs.readfile("/var/etc/smartdns/blacklist-ip.conf")
end

function addr.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("/var/etc/smartdns/blacklist-ip.conf", value)
end

-- Doman addresss
s = m:section(TypedSection, "smartdns", translate("Technical Support"), 
	translate("Technical Support"))
s.anonymous = true

o = s:option(Button, "web")
o.title = translate("SmartDNS official website")
o.inputtitle = translate("open website")
o.inputstyle = "apply"
o.write = function()
	luci.http.redirect("https://pymumu.github.io/smartdns")
end

o = s:option(Button, "Donate")
o.title = translate("Donate to smartdns")
o.inputtitle = translate("Donate")
o.inputstyle = "apply"
o.write = function()
	luci.http.redirect("https://pymumu.github.io/smartdns/#donate")
end

return m

