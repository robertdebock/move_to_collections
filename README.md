# Move to Collections

Ansible introduced collections in Ansible 2.8. More and more modules (that came with Ansible) will move to collections.

Ansible has changed a lot in the last few releases. It's a bit confusing, so here is my attempt to clear up what happened over time.

|Package     |Version|Description                                                       |
|------------|-------|------------------------------------------------------------------|
|ansible     |<=2.7  |Ansible and modules, all as a single package.                     |
|ansible     |2.8    |Introduced collections, all modules still shipped in this package.|
|ansible     |2.10   |Only collections, depends on ansible-base.                        |
|ansible-base|2.10   |Just ansible, no collections.                                     |
|ansible-core|2.11   |Just ansible, no collections.                                     |
|ansible     |3.0.0  |Just ansible, depends on ansible-base.                            |

Okay, in other words;

1. There was a package called `ansible` including everything. (ansible<=2.7)
2. The package `ansible` contained only collections, not the framework. The framework in in `ansible-base`, which is a dependency of `ansible`. (ansible>=2.10<=3)
3. The package `ansible-core` contains the Ansible framework. (ansible==2.11)
4. The package `ansible` contains the Ansible framework. (ansible==3.*)

Wow, still confusing.
