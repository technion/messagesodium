# Messagesodium

Project status: Turbo Pre-alpha

Patches Cookiestore to use libsodium for encryption and verification.

# Cookistore

Rails [Cookiestore](https://www.justinweiss.com/articles/how-rails-sessions-work/) is a heavily underrated feature. It bought commonsense to session management at a time when [saving every user session in its own tmpfile on a server](http://php.net/manual/en/function.session-start.php) was slow and unreasonable to scale, and XXX.

This gem brings an alternative backend to CookieStore.

# Use

Just insert this gem into your Gemfile like any other:

    gem 'messagesodium'

And run your usual bundle installation. Any existing sessions will be invalidated, much like if you changed your secret key.
You can test it is active by looking at any session cookie. The absence of the "--" delimeter will confirm you are using this gem.

# Demonstration

[This gist](https://gist.github.com/technion/5cb2c6fbc570f6c1bc66e30bfb072cdf) shows a few interesting benchmarks, which we can refer to when describing what this gem offers.

```

Cookiestore data is: SWFQbTg0dCtheE45TXU0dWRtT25ndjJVSEdWTE8vei9LMVpZYWVjaWZjaFppdUk5aklVRWZEUy9TOUJuMFpYd2dDMndVZkt0eTR5Sm04Y1FjQzk0M00wRnhTRERHdDhnT3c1dTBvTnRad009LS16WlFaeE82dy84VzA4NThYQzk5bTVBPT0=--efcb8809421d2dc1665c9d9afa9638c1c2a763eb
which is 222 in length
Sodium data is: SGwQn0DD+pOvTPo68nvNYQLRFMt+Mf7rFU6BkiKhA0qHGT8BHVuqXRqEOYy+xcOoMCCRh99eeb/sVWlPzA4/FavTyg4U0PUAns0bx/Q9j4gcoD6K/h0z8yZvW0425g==
which is 128 in length
                                       user     system      total        real
to_json                            2.470000   0.000000   2.470000 (  2.514048)
JSON.dump                          0.520000   0.000000   0.520000 (  0.534084)
cookiestore encrypt and sign       1.810000   0.030000   1.840000 (  1.915375)
cookiestore decrypt and verify     2.730000   0.000000   2.730000 (  2.824819)
libsodium encrypt and sign         1.580000   0.060000   1.640000 (  1.738750)
libsodium decrypt                  1.010000   0.000000   1.010000 (  1.035354)

```

## Smaller cookies

A welcome consequence is that of smaller cookies. This isn't strictly the result of changed encryption algorithms, but CookieStore's message packing is somewhat ineffecient. It is effectively:

    Base64(Base64(iv) || "--" || Base64(message)) || "--" HMAC

If you can understand the reasoning for double Base64 encoding you're smarter than I am, but it adds to the four delimiting bytes. The authenticator on Poly1305 is also four bytes shorter than SHA1. You can see the end result in the above benchmark - 222 bytes vs 128 for our sample.

Smaller cookies are a good thing. It's less data on the wire for every single page hit, and it's more room to move around the 4Kb limit.

## More performant

The above benchmark shows our approach as much more performant. Some of that is just crypto, which can be hardware dependant.

But some of this is down to the message packing. Dipping into Base64 functions three separate times to open one cookie is ineffecient. When the IV is known to be of BLOCKSIZE length, choosing to cut it by using split() and a delimiter is the long way around. In the end, performance is great.

## A modern security approach

Let's be clear about the fact that I have no known issue with the current CookieStore implementation. However, it's worth having a read of the view of [Google's Adam Langley](https://www.imperialviolet.org/2013/10/07/chacha20.html) when describing "a strong motivation to replace it" when describing CBC mode.

Indeed, the are several comments in the original Rails source code to the effect of "this dance is done in the hope we don't introduce a vulnerability".

What you'll find in this gem is a much smaller, more easily audited codebase without any hoops to jump through.

# Approach

This gem is designed largely as a drop-in replacement for MessageEncryptor, which in turn is used by CookieStore. In a defualt environment, Rails astracts away everything I say below.

MessageEncryptor takes a "secret", and a "signing secret", using them as two different secrets. Libsodium only needs a 256-bit secret.

MessageEncryptor offers the option to provide an OpenSSL cipher. Obviously none of these apply to our gem. Finally, MessageEncryptor offers its choice of serializers. It defaults to Marshal, which was always a bad move, so Rails started to implicitly set JSON as the serializer in version 4.1. There's no reason in my view to let people have a footgun like this, so all this gem supports is JSON.

In order to make this "drop in", all the above parameters can still be provided, they are just ignored.
