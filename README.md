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
2. The package `ansible` contained only collections, not the framework. The framework is in `ansible-base`, which is a dependency of `ansible`. (ansible>=2.10<=3)
3. The package `ansible-core` contains the Ansible framework. (ansible==2.11)
4. The package `ansible` contains the Ansible framework. (ansible==3.*)

Wow, still confusing.

## Adding translations.

The file `from_to.txt` contains lines that map the name of the old module to the new one. For example:

```text
gluster_volume gluster.gluster.gluster_volume
```

Feel free to make pull requests to add more mappings.

## Running the script.

Go into the directory of your role and run:

```shell
/path/to/move_to_collections/transform.sh
```

You'll get some output what the script is doing. Feel free to inspect the differences. Here is what you can expect:

1. The `tasks/*.yml` files will be transformed.
2. The `handlers/main.yml` file will be transformed.
3. The `requirements.yml` file will list all required collections.


## See also

https://www.youtube.com/watch?v=jOXiSaHbZVk
