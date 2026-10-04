# Release-only R8 compatibility rules.
# Apache Tika references StAX's XMLStreamException, which is not part of the
# Android runtime. The referenced code path is not used by Pocket Inventory,
# so R8 may safely ignore this optional desktop-Java type.
-dontwarn javax.xml.stream.XMLStreamException
