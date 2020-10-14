# falcon-tools

A toolbox for researching and hacking NVIDIA Falcon microprocessors.

The generic goal is to provide a collection of tools, exploits and code for demystifying the Falcon and
its cryptographic functionality to ease up research for people interested in the cryptosystem.

## Components

* [keygenldr](./keygenldr): A set of ROP chains for obtaining keys used by the KeygenLdr payload of the
Nintendo Switch TSEC firmware.

* [libfaucon](./libfaucon): A standard library for Falcon firmware development

* [tools](./tools): Helper scripts for working with Falcon firmware blobs

## Credits

The exploits and tools collected in this repository were developed by [**Thog**](https://github.com/Thog)
and [**vbe0201**](https://github.com/vbe0201).

We credit the following people for their great contributions to this project:

* [Elise](https://github.com/EliseZeroTwo) for help and advise in the early stage

* [SciresM](https://github.com/SciresM) for being very helpful and informative throughout our research

## Licensing

This software is licensed under the terms of the GNU GPLv2.

See the [LICENSE](./LICENSE) file for details.
