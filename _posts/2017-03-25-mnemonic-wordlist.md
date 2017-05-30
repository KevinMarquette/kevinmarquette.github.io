---
layout: post
title: "Mnemonic wordlist"
date: 2017-03-25
tags: [Other]
---

We were having a conversation recently at work about server naming conventions and it reminded of an article where the author was using a mnemonic word list to name servers. After a little digging, I was able to track it down.<!--more-->

# Index

* TOC
{:toc}

# A proper server naming scheme

The original post was [A proper server naming scheme](http://mnx.io/blog/a-proper-server-naming-scheme/) over at mnx.io. It is worth a read, but some of the links are outdated. It looks like the original mnemonic encoding project (from Oren Tirosh) that was referenced has vanished. That was the project that contained the word list that I was looking for.

# Oren Tirosh’s Mnemonic Encoding Project

I was able to track down a copy of the [mnemonicode project](https://github.com/singpolyma/mnemonicode). It looks like Oren compiled a list of 1626 words that could be used to encode or decode information. The words have been chosen to be easy to understand when spoken over the phone.

## From the readme

Mnemonic tries to be selective about its word list. Its criteria are thus:

### Mandatory Criteria:

 - The wordlist contains 1626 words.
 - All words are between 4 and 7 letters long.
 - No word in the list is a prefix of another word (e.g. visit,
   visitor).
 - Five letter prefixes of words are sufficient to be unique. 

### Less Strict Criteria:

  - The words should be usable by people all over the world. The list
    is far from perfect in that respect. It is heavily biased towards
    western culture and English in particular. The international
    vocabulary is simply not big enough. One can argue that even words
    like "hotel" or "radio" are not truly international. You will find
    many English words in the list but I have tried to limit them to
    words that are part of a beginner's vocabulary or words that have
    close relatives in other european languages. In some cases a word
    has a different meaning in another language or is pronounced very
    differently but for the purpose of the encoding it is still ok - I
    assume that when the encoding is used for spoken communication
    both sides speak the same language.

  - The words should have more than one syllable. This makes them
    easier to recognize when spoken, especially over a phone
    line. Again, you will find many exceptions. For one syllable words
    I have tried to use words with 3 or more consonants or words with
    diphthongs, making for a longer and more distinct
    pronunciation. As a result of this requirement the average word
    length has increased. I do not consider this to be a problem since
    my goal in limiting the word length was not to reduce the average
    length of encoded data but to limit the maximum length to fit in
    fixed-size fields or a terminal line width.

  - No two words on the list should sound too much alike. Soundalikes
    such as "sweet" and "suite" are ruled out. One of the two is
    chosen and the other should be accepted by the decoder's
    soundalike matching code or using explicit aliases for some words.

  - No offensive words. The rule was to avoid words that I would not
    like to be printed on my business card. I have extended this to
    words that by themselves are not offensive but are too likely to
    create combinations that someone may find embarrassing or
    offensive. This includes words dealing with religion such as
    "church" or "jewish" and some words with negative meanings like
    "problem" or "fiasco". I am sure that a creative mind (or a random
    number generator) can find plenty of embarrassing or offensive word
    combinations using only words in the list but I have tried to
    avoid the more obvious ones. One of my tools for this was simply a
    generator of random word combinations - the problematic ones stick
    out like a sore thumb.

  - Avoid words with tricky spelling or pronunciation. Even if the
    receiver of the message can probably spell the word close enough
    for the soundalike matcher to recognize it correctly I prefer
    avoiding such words. I believe this will help users feel more
    comfortable using the system, increase the level of confidence and
    decrease the overall error rate. Most words in the list can be
    spelled more or less correctly from hearing, even without knowing
    the word.

  - The word should feel right for the job. I know, this one is very
    subjective but some words would meet all the criteria and still
    not feel right for the purpose of mnemonic encoding. The word
    should feel like one of the words in the radio phonetic alphabets
    (alpha, bravo, charlie, delta etc).


# The word list

Here is a sample from the middle of the list:

    lobster  local    logic    logo     lola     london   
    lucas    lunar    machine  macro    madam    madonna  
    madrid   maestro  magic    magnet   magnum   mailbox  
    major    mama     mambo    manager  manila   marco    
    marina   market   mars     martin   marvin   mary     
    master   matrix   maximum  media    medical  mega     
    melody   memo     mental   mentor   mercury  message  
    metal    meteor   method   mexico   miami    micro    
    milk     million  minimum  minus    minute   miracle  
    mirage   miranda  mister   mixer    mobile   modem    
    modern   modular  moment   monaco   monica   monitor  
    mono     monster  montana  morgan   motel    motif    
    motor    mozart   multi    museum   mustang  natural  
    neon     nepal    neptune  nerve    neutral  nevada   
    news     next     ninja    nirvana  normal   nova     
    novel    nuclear  numeric  nylon    oasis    observe  
    ocean    octopus  olivia   olympic  omega    opera    
    optic    optimal  orange   orbit    organic  orient   
    origin   orlando  oscar    oxford   oxygen   ozone    
    pablo    pacific  pagoda   palace   pamela   panama   
    pancake  panda    panel    panic    paradox  pardon   
    paris    parker   parking  parody   partner  passage  

I have reproduced the entire [word list here](\public\mnemonicwordlist.txt) and on [GitHubGist](https://gist.github.com/KevinMarquette/343c2436d24539cc5eabacbfd98ab754) to make it easy to find. It was extracted from the [mn_wordlist.c](https://github.com/singpolyma/mnemonicode/blob/master/mn_wordlist.c) file in the project.

## Craig G's MnemonicEncodingWordList Project

After I published this post, Craig created a small [project](https://github.com/chelnak/MnemonicEncodingWordList) in PowerShell to work with this list. In that project he has the full list in a [json document](https://github.com/chelnak/MnemonicEncodingWordList/blob/master/mnemonics.json).

# Save this for future reference

I don't have an immediate need for this list, but it took be a bit longer to find it than I expected. I know I could use any word list but this one was carefully crafted and I wanted to preserve it. I hope you find a valuable use for it. I know I am saving this one for later.
