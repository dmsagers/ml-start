xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:saveBook(
    $title as xs:string,
    $author as xs:string?,
    $year as xs:string?,
    $price as xs:string?,
    $category as xs:string?
) as xs:string {
    let $id as xs:string := local:generateID()
    let $book as element(book) :=
        element book {
            attribute category { $category },
            attribute id { $id },
            element title { $title },
            element author { $author },
            element year { $year },
            element price { $price }
        }

    let $uri := '/bookstore/book-' || $id || '.xml'
    let $save := xdmp:document-insert($uri, $book)
    return
        $id
};

declare function local:generateID(
) as xs:string {
    let $hash :=
        xs:string(
            xdmp:hash64(
                fn:concat(
                    xs:string(xdmp:host()),
                    xs:string(fn:current-dateTime()),
                    xs:string(xdmp:random())
                )
            )
        )
    return
        local:padString($hash, 20, fn:false())
};

declare function local:padString(
    $string as xs:string,
    $length as xs:integer,
    $padLeft as xs:boolean
) as xs:string {
    if (fn:string-length($string) = $length) then (
        $string
    ) else if (fn:string-length($string) < $length) then (
        if ($padLeft) then (
            local:padString(fn:concat("0", $string), $length, $padLeft)
        ) else (
            local:padString(fn:concat($string, "0"), $length, $padLeft)
        )
    ) else (
        fn:substring($string, 1, $length)
    )
};

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

declare variable $id as xs:string? :=
    if (xdmp:get-request-method() eq "POST") then (
        let $title as xs:string? := local:sanitizeInput(xdmp:get-request-field("title"))
        let $author as xs:string? := local:sanitizeInput(xdmp:get-request-field("author"))
        let $year as xs:string? := local:sanitizeInput(xdmp:get-request-field("year"))
        let $price as xs:string? := local:sanitizeInput(xdmp:get-request-field("price"))
        let $category as xs:string? := local:sanitizeInput(xdmp:get-request-field("category"))
        return
            local:saveBook($title, $author, $year, $price, $category)
    ) else ();

(: build the html :)
xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="/css/style.css"/>
        <title>Add a Book</title>
    </head>
    <body>
        <div class="nav-container">
            <a href="book-list.xqy" class="nav-item">Find a Book</a>
            <a href="add-book.xqy" class="nav-item">Add books to Library</a>
            <a href="content-admin.xqyy" class="nav-item">Books Admin Page</a>
        </div>
        <h1 class="mainTitle">Add Books to Library</h1>
        {
        if (fn:exists($id) and $id ne '') then (
            <div class="message">Book Saved! ({$id})</div>
        ) else ()
        }
        <form name="add-book" action="add-book.xqy" method="post">
            <div class="table-data-container">
                <legend>Add Book</legend>
                <label class="table-data-edit" for="title">Title</label> <input type="text" id="title" name="title"/>
                <label class="table-data-edit" for="author">Author</label> <input type="text" id="author" name="author"/>
                <label class="table-data-edit" for="year">Year</label> <input type="text" id="year" name="year"/>
                <label class="table-data-edit" for="price">Price</label> <input type="text" id="price" name="price"/>
                <label class="table-data-edit" for="category">Category</label>
                <select name="category" id="category">
                    <option/>
                    {
                    for $c in ('CHILDREN','FICTION','NON-FICTION')
                    return
                        <option value="{$c}">{$c}</option>
                    }
                </select>
                <input type="submit" value="Save"/>
            </div>
        </form>
    </body>
</html>