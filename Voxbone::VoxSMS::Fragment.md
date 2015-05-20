# NAME

Voxbone::Fragment - Utility Library To Find Optimal Size of SMS messages

# SYNOPSIS

    use Voxbone::Fragment;
    my  @fragments = voxsms_fragment_message($msg); # returns an array of fragments

# DESCRIPTION

This method determines the most compact encoding that can be uses for the given message and splits the message based on the maximum length for that encoding

# AUTHOR

Torrey Searle <torrey@voxbone.com>
